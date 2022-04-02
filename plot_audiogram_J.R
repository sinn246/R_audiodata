# plot_audiogram_J オージオグラムを描く
#入力：data.frameのうち1行分　列名が"LAxxx"だと左気導xxxHz RByyyだと右骨導yyyHz の聴力閾値　
#   スケールアウトは　”zzz+” のように数字の後に"+"をつけるとスケールアウトと扱う
#文字の大きさなどをデフォルトから変更したい場合は以下の引数を操作
#返値：ggplotのグラフなので、それを表示したり、印刷したり、他のグラフに組み込んだりしてください

plot_audiogram_J <- function(df,
                             width=80, # グラフの横のサイズ（mm) これに合わせてフォント・点の大きさを調整
                             BW = FALSE, #　白黒ならTRUE
                             x_position="top", #X軸の位置　"bottom"だと下に置く
                             my_theme = NA, # theme_xxを追加したいときここにいれてください
                             point_scale = 1.0, #点の大きさの調節
                             point_stroke_scale = 1.0, #○✗の太さ
                             text_scale = 1.0, #文字の大きさの調節
                             line_scale = 1.0, #線の太さの調節
                             zero_scale = 1.0, #0dB水平線の太さ
                             xlab = "周波数 (Hz)", ylab = "聴力レベル (dB)"
){
  basic_size = width/120 + 0.3
  
  text_size = width *0.12 * text_scale
  point_size = width *0.04 * point_scale
  point_stroke = basic_size *2/3 * point_stroke_scale
  line_size = basic_size*0.4 * line_scale
  zero_size = basic_size*0.4 * zero_scale
  
  shift_haba = 0.2 # point_size / 20
  yajirusi_tate = 6
  yajirusi_yoko = 4 / 20
  arrow_len = width / 60
  cs <- str_subset(colnames(df),"^[LR][AB]\\d+$")
  nc <- ncol(df)
  ldf <- df %>% mutate(across(1:all_of(nc),as.character)) %>%
    pivot_longer(all_of(cs),names_to = c("ear","mode","freq"),names_pattern = "^(\\D)(\\D)(\\d+)$",values_to = "dB" ) %>%
    subset(!is.na(dB)) %>%
    mutate(SO = ifelse(is.na(suppressWarnings(as.numeric(dB))), str_sub(dB,-1,-1),NA)) %>%
    mutate(dB = as.numeric(ifelse(is.na(suppressWarnings(as.numeric(dB))), str_sub(dB,0,-2),dB))) %>%
    mutate(freq = log2(as.numeric(freq)/125)) %>%
    mutate(pch = ifelse(ear=="R",ifelse(mode=="A",1,91),ifelse(mode=="A",4,93))) %>%
    mutate(col0 = ifelse(ear=="L","blue","red")) %>%
    mutate(col1 = if(BW) "black"else col0) %>%
    mutate(shift = ifelse(mode=="A",0,ifelse(ear=="R",-shift_haba,shift_haba)))
  
  ldfa <- subset(ldf,(mode=="A" & !is.na(dB))) %>%
    arrange(ear,freq) %>%
    mutate(lSO = lag(SO)) %>%
    mutate(lfreq = lag(freq)) %>%
    mutate(ldB = lag(dB)) %>%
    mutate(lty = ifelse(ear=="R","solid","11"))
  ldfa <- subset(ldfa,(freq>lfreq & is.na(SO) & is.na(lSO)))
  
  ldfso <- subset(ldf,SO=="+") %>%
    mutate(dir = ifelse(ear=="R",-1,1))
  
  ggp <- ggplot() +
    scale_shape_identity() +
    scale_color_identity() +
    scale_linetype_identity() +
    geom_hline(yintercept = 0,size=zero_size) +
    geom_point(data=ldf,aes(x=freq+shift,y=dB,shape=pch,color=col1),size=point_size,stroke=point_stroke)+
    geom_segment(data=ldfa,aes(x=lfreq,y=ldB,
                               xend=freq,yend=dB,
                               linetype=lty,color=col1),size=line_size)+
    geom_segment(data=ldfso,aes(x=freq+shift+yajirusi_yoko*dir*0.45
                                ,y=dB+yajirusi_tate*0.45,
                                xend=freq+shift+yajirusi_yoko*dir,
                                yend=dB+yajirusi_tate,
                                color=col1),size=line_size/2,arrow = arrow(length = unit(arrow_len, "mm")))+
    coord_fixed(ratio = 1/20,ylim = c(120,-20),xlim=c(-0.5,6.5),expand=FALSE)+
    scale_y_reverse(breaks = seq(-20, 120, by=10))+ 
    scale_x_continuous(breaks=c(0,1,2,3,4,5,6),labels=c("125","250","500","1,000","2,000","4,000","8,000"),
                       position = "top") +
    labs(x = xlab, y = ylab)
  
  if(length(str_subset(colnames(df),"^Title$"))>0){
    ggp <- ggp + ggtitle(df$Title)
  }
  if(!is.na(my_theme)){
    ggp <- ggp + my_theme
  }
  
  return(ggp+theme(panel.grid.minor = element_blank(),
                   panel.border = element_rect(colour = "black",size=zero_size*2),
                   plot.title = element_text(hjust = 0.5),
                   text = element_text(size=text_size),
                   axis.ticks = element_blank()
                   #   ,axis.text.x = element_text(angle=90, hjust=1) #コメントを消すとX軸が縦書きに
  ))
}

# plotGroupMean 多数の聴力図を重ねたもの、及び平均聴力を描く
#入力：data.frameのうち必要分のデータ　列名が"LAxxx"だと左気導xxxHz RByyyだと右骨導yyyHz の聴力閾値
#  としていますが、術前術後の変化などなら他の文字にしても構いません。アルファベット順に処理されると思います。
#   スケールアウトは対応しないので、予めスケールアウトなら+5dB として扱う、欠測値とするなど予め処理しておく必要あり
#ラベルは変更できます。気導、骨導などにしていますが、術前／術後にするとか

plotGroupMean <- function(
  df,
  xlab = "周波数 (Hz)", ylab = "聴力レベル (dB)",
  labels = c("気導","骨導")
){
  cs <- str_subset(colnames(df),"^\\D\\D\\d+$")
  nc <- ncol(df)
  df %>% rowid_to_column("RID") %>%
    mutate(across(1:all_of(nc),as.character))  -> df
  ldf <- df %>% 
    pivot_longer(all_of(cs),names_to = c("ear","mode","freq"),names_pattern = "^(\\D)(\\D)(\\d+)$",values_to = "dB" ) %>%
    subset(!is.na(dB)) %>%
    mutate(SO = ifelse(is.na(suppressWarnings(as.numeric(dB))), str_sub(dB,-1,-1),NA)) %>%
    mutate(dB = as.numeric(ifelse(is.na(suppressWarnings(as.numeric(dB))), str_sub(dB,0,-2),dB))) %>%
    mutate( dB = dB + ifelse(is.na(SO),0,5)) %>%
    mutate(freqN = log2(as.numeric(freq)/125))
  
  ldf$mode <- factor(ldf$mode,labels = labels)
  return(
    ggplot()+
      facet_grid(. ~ mode, scales = "free",space = "free") +
      geom_line(data=ldf,aes(x=freqN, y=dB,group=interaction(RID, ear),linetype=ear,color=ear),lwd = 0.2)+
      stat_summary(data = ldf,
                   aes(x=freqN, y=dB,group=ear,linetype=ear,color=ear),
                   fun=mean, orientation = "x",
                   geom="line", lwd = 1.0)+
      stat_summary(data = ldf,
                   aes(x=freqN, y=dB,group=ear,linetype=ear,color=ear,width=0.1),
                   fun.data = mean_cl_normal, orientation = "x",
                   geom="errorbar", lwd = 1.0)+
      coord_cartesian(ylim = c(120,-10))+
      scale_y_reverse( breaks = seq(-10, 110, by=10),expand = expansion())+
      scale_x_continuous(breaks =unique(ldf$freqN), expand = expansion(add=0.5), labels = unique(ldf$freq))+
      labs(x = xlab, y = ylab)
  )
}

