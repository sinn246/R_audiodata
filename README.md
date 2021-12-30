# R_audiodata
大量の聴力検査データの集計とグラフ化を行うRプログラム
 （＋サンプルデータ)

# DEMO

(under construction...)

# Features
 
自動的にファイルを処理するスクリプト、データからオージオグラムを作成するスクリプトを作りました。
出力はサンプルではPDFにしていますが、他のフォーマットでも出力可能です。

# Requirement
 
まずRが必要です。
Rstudioは必ずしも必要ではありませんが、使うことをおすすめします。

グラフ作成はggplot2および色々データ処理をしますのでdplyrというパッケージをインストールするといいと思います

# Installation
 
RおよびRstudioのインストールはネットその他で調べてください。
Rstudio メニューからFile ＞ New Project..　を選択
Version Control > Git で出てくるダイアログウィンドウのRepository URL に　https://github.com/sinn246/R_audiodata を指定
でプロジェクトが作成できると思います。

# Usage
 
スクリプト　XLSXs_to_csv.R　はエクセルの複数のXSLXファイルを読み込んで一つのcsvファイルを作ります。
XSLXファイルの構成、データ内容に合わせて変更してください。

できたcsvファイルからオージオグラムを作るサンプルがplot_sample1.Rです。
各症例のグラフ、平均聴力などのグラフが作れます。

# Note
 
自動でデータを処理してくれるソフト、ということではなく状況に応じて書き換えて使うことを想定しています。ある程度のプログラミングの知識が必要です。

# Author
 
* 作成者：Shin-ichi Nishimura
* 所属:この仕事に所属先は関係していません
* e-mail s246 <atmark> nifty.com

# License

フリーですが、論文を書いたりする学術的なことに使うことを想定しています
不特定多数を相手にした営利目的には使ってほしくないなと思います
