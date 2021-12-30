library(tidyverse)
library(RColorBrewer)
library(patchwork)
library(gridExtra)
source("plot_audiogram_J.R")


theme_set(theme_bw(base_family="Japan1"))

cause <- c(
  "蝸牛奇形",
  "内耳道・蝸牛神経管狭窄",
  "先天性サイトメガロウイルス感染症",
  "その他先天性感染症（風疹等）",
  "その他原因が明らかな疾患",
  "突発性難聴",
  "聴神経腫瘍",
  "メニエール病",
  "外リンパ瘻",
  "音響外傷",
  "その他外傷",
  "ムンプス",
  "髄膜炎",
  "その他の原因が明らかな疾患",
  "原因不明（先天性）",
  "原因不明"
)

res <- read_csv("OUTPUT/merged_data_SO.csv")

res %>%  filter(!is.na(Cause))  -> res

res$Cause <- factor(res$Cause,cause)

res %>% mutate(Title = paste(ID,Facility)) -> res

for(c in cause){
  r0 <- filter(res,res$Cause==c)
  print(sprintf("%s has %d cases",c,nrow(r0)))
  if(nrow(r0)>0){
    audiograms <- list()
    for(i in 1:nrow(r0)){
      audiograms[[i]] <- plot_audiogram_J(r0[i,],width=40) 
    }
    ml <- marrangeGrob(audiograms, nrow=5, ncol=4, top="")
    ggsave(file=sprintf("OUTPUT/audios-%s.pdf",c),plot=ml,dpi=300,width = 8,height=11.5)
  }
}


#####################
res <- read_csv("OUTPUT/merged_data.csv")

res %>%  filter(!is.na(Cause))  -> res

res$Cause <- factor(res$Cause,cause)
res %>% mutate(Title = paste(ID,Facility)) -> res

#　X　から始まるのが悪い方の聴力　Y がいい方の聴力
res %>%
  mutate(RA3 = (RA500+RA1000+RA2000)/3,LA3 = (LA500+LA1000+LA2000)/3) %>%
  mutate(XA125 = if_else(RA3>LA3,RA125,LA125),YA125 = if_else(RA3<LA3,RA125,LA125)) %>%
  mutate(XA250 = if_else(RA3>LA3,RA250,LA250),YA250 = if_else(RA3<LA3,RA250,LA250)) %>%
  mutate(XA500 = if_else(RA3>LA3,RA500,LA500),YA500 = if_else(RA3<LA3,RA500,LA500)) %>%
  mutate(XA1000 = if_else(RA3>LA3,RA1000,LA1000),YA1000 = if_else(RA3<LA3,RA1000,LA1000)) %>%
  mutate(XA2000 = if_else(RA3>LA3,RA2000,LA2000),YA2000 = if_else(RA3<LA3,RA2000,LA2000)) %>%
  mutate(XA4000 = if_else(RA3>LA3,RA4000,LA4000),YA4000 = if_else(RA3<LA3,RA4000,LA4000)) %>%
  mutate(XA8000 = if_else(RA3>LA3,RA8000,LA8000),YA8000 = if_else(RA3<LA3,RA8000,LA8000)) %>%
  mutate(XB250 = if_else(RA3>LA3,RB250,LB250),YB250 = if_else(RA3<LA3,RB250,LB250)) %>%
  mutate(XB500 = if_else(RA3>LA3,RB500,LB500),YB500 = if_else(RA3<LA3,RB500,LB500)) %>%
  mutate(XB1000 = if_else(RA3>LA3,RB1000,LB1000),YB1000 = if_else(RA3<LA3,RB1000,LB1000)) %>%
  mutate(XB2000 = if_else(RA3>LA3,RB2000,LB2000),YB2000 = if_else(RA3<LA3,RB2000,LB2000)) %>%
  mutate(XB4000 = if_else(RA3>LA3,RB4000,LB4000),YB4000 = if_else(RA3<LA3,RB4000,LB4000)) -> res

select(res,-str_subset(colnames(res),"^[LR]\\D\\d+$")) -> res
nc <- ncol(res)
res %>% select(1:nc) %>% mutate(across(1:nc,as.character)) -> res 

glist <- list()
n <- 1

for(c in cause){
  r0 <- filter(res,res$Cause==c)
  print(sprintf("%s has %d cases",c,nrow(r0)))
  if(nrow(r0)>0){
    glist[[n]] <- plotGroupMean(r0)+ theme(legend.position = 'none')+ggtitle(c)
    n = n+1
  }
}

ml <- marrangeGrob(glist, nrow=3, ncol=1, top="")
ggsave(file="OUTPUT/plots.pdf",plot=ml,dpi=300,width = 8,height=11.5)
