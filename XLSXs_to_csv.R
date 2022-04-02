library(readxl)
library(tidyverse)
library(logr)


log_open("merge")

outfolder <- "OUTPUT"
if(!file.exists(outfolder)) {
  dir.create(outfolder)
}


cnames <- c("Facility","ID","Age","Sex","Cause0","Cause",
            "RA125","RA250","RA500","RA1000","RA2000","RA4000","RA8000",
            "LA125","LA250","LA500","LA1000","LA2000","LA4000","LA8000",
            "RB250","RB500","RB1000","RB2000","RB4000",
            "LB250","LB500","LB1000","LB2000","LB4000",
            "Kainyuu","Method","HA","Comment")

datafolder = "DATA/"
files = dir(path=datafolder,pattern = "*.xlsx")
res <- NULL

for(f0 in files){
  f <- paste0(datafolder,f0)
  d0 <- read_xlsx(f,sheet=2) #2シート目を読み込む
  shisetumei <- colnames(d0)[3]
  if(shisetumei=="...3"){ #施設名が空欄のとき
    shisetumei <- f0
  }
  d <- read_xlsx(f,sheet=2,skip=8)　#2シート目 先頭8行を無視して読み込む
  d %>% mutate(blank = "") %>%
    select(1:33) %>% mutate(across(1:33,as.character)) %>%
    add_column(facility = shisetumei,.before="...1") -> dx
  colnames(dx) <- cnames
  if(is.null(res)){
    res <- dx
  }else{
    res <- bind_rows(res,dx)
  }
  log_print(sprintf("File:%s 施設:%s  %d cases",f,shisetumei,nrow(dx)))
}

#年齢に余計なものがついていたら除去

for(r in 1:nrow(res)){
  i = pull(res[r,3])
  if(!is.na(i) && is.na(suppressWarnings( as.numeric(i)))){
    ix = str_extract(i,"\\d+")
    if(is.na(ix)){
      log_print(sprintf("Age:%s had no digit",i))
    }else{
      log_print(sprintf("Age:%s turned to %s",i,ix))
      res[r,3] = ix
    }
  }
}


#スケールアウト対応

list_scaleout = c("","","","","","",
                  "70+","90+","110+","110+","110+","110+","100+",
                  "70+","90+","110+","110+","110+","110+","100+",
                  "55+","65+","70+","70+","60+",
                  "55+","65+","70+","70+","60+"
)

for(c in 7:30){
  for(r in 1:nrow(res)){
    i = pull(res[r,c])
    if(!is.na(i) && is.na(suppressWarnings( as.numeric(i)))){
      ix = str_extract(i,"\\d+")
      if(is.na(ix)){
        ix = list_scaleout[c]
      }else{
        ix = paste0(ix,"+")
      }
      log_print(sprintf("SO:%s changed to %s",i,ix))
      res[r,c] = ix
    }
  }
}

#######################打ち間違いの修正
to_replace <- c(
  "その他原因が明らかな疾患", "その他の原因が明らかな疾患",
  "先生性サイトメガロウイルス感染症","先天性サイトメガロウイルス感染症",
  "突発性難聴\r\n" ,"突発性難聴",
  "突発性難聴\r\r\n突発性難聴","突発性難聴",
  "先天性難聴","原因不明"
)

v0 <- to_replace[c(TRUE,FALSE)]
v1 <- to_replace[c(FALSE,TRUE)]

for(r in 1:nrow(res)){
  i = pull(res[r,6])
  for(n in 1:length(v0)){
    if(!is.na(i) && i == v0[n]){
      res[r,6] = v1[n]
      log_print(sprintf("Replace:%s to %s in row %d",v0[n],v1[n],r))
    }
  }
}


#######原因不明（先天性）を分ける

for(r in 1:nrow(res)){
  c0 = pull(res[r,5])
  c = pull(res[r,6])
  if(is.na(c0) || c0 == "先天性疾患"){
    if(!is.na(c) && c == "原因不明"){
      res[r,6] = "原因不明（先天性）"
      log_print(sprintf("Replace:原因不明（先天性） in row %d",r))
    }
  }
}

#性別の修正
for(r in 1:nrow(res)){
  c0 = pull(res[r,4])
  if(is.na(c0) || c0 == "F"){
    res[r,4] = "女"
  }else if(is.na(c0) || c0 == "M"){
    res[r,4] = "男"
  }
}

#介入の修正
for(r in 1:nrow(res)){
  c0 = pull(res[r,"Method"])
  if(!is.na(c0)){
    if(is.na(res[r,"Kainyuu"])){
      res[r,"Kainyuu"] = "有"
    }else if(pull(res[r,"Kainyuu"])=="無"){
      res[r,"Kainyuu"] = "有"
    }
    if(c0 == "気導クロス補聴器"){
      res[r,"HA"] = "気導クロス補聴器"
      res[r,"Method"] = "補聴器"
    }
    if(c0 == "気導補聴器"){
      res[r,"HA"] = "気導補聴器"
      res[r,"Method"] = "補聴器"
    }
    c = pull(res[r,"HA"])
    if(!is.na(c)){
      if(!is.na(str_extract(c,"不明"))){
        log_print(sprintf("Replace:%s in row %d to NA",pull(res[r,"HA"]),r))
        res[r,"HA"] = NA
      }else if(c=="気導"){
        res[r,"HA"] = "気導補聴器"
      }
    }
  }else{
    c = pull(res[r,"HA"])
    if(!is.na(c)){
      res[r,"Method"] = "補聴器"
      log_print(sprintf("Replace:Method NA, HA %s in row %d ",c,r))
    }else{
      c = pull(res[r,"Kainyuu"])
      if(!is.na(c)){
        if(c=="有"){
          res[r,"Kainyuu"] = "無"
          log_print(sprintf("Replace:介入あり, method NA in row %d ",r))
        }
      }
    }
  }
}



write_excel_csv(res,paste0(outfolder,"/merged_data_SO.csv"),na="")

list_scaleout_num = c("","","","","","",
                      "75","95","115","115","115","115","105",
                      "75","95","115","115","115","115","105",
                      "60","70","75","75","65",
                      "60","70","75","75","65"
)

for(c in 7:30){
  for(r in 1:nrow(res)){
    i = pull(res[r,c])
    if(!is.na(i) && is.na(suppressWarnings( as.numeric(i)))){
      ix = str_extract(i,"\\d+")
      if(is.na(ix)){
        ix = list_scaleout_num[c]
      }else{
        ix = as.character(5+as.integer(ix))
      }
      log_print(sprintf("~SO:%s changed to %s",i,ix))
      res[r,c] = ix
    }
  }
}
write_excel_csv(res,paste0(outfolder,"/merged_data.csv"),na="")
log_close()
