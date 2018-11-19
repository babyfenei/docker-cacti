# Cacti图形数据自动导出脚本
# 本脚本通过自动查询图形树中所有的图形编号和图形名称，使用wget工具进行下载，
# 在图形树中添加图形以后，导出系统会在执行前自动查询数据库中最新的列表。
# 您要做的就是，将您需要导出的图形添加至图形树即可。
  
#使用此脚本前应首先更改Cacti图形和数据导出网页的验证模式，更改完毕后可免验证登录，有一定的风险，请慎重！
#注释掉graph_image.php和graph_xport.php文件中 [include("./include/auth.php");]行
#添加[include("./include/global.php");]
  
#使用以下命令添加crontab自动下载列表 我这里添加的是每日00：01分进行下载。添加完成后重启crond服务
#我这里将脚本文件保存在cacti文件夹中的file文件夹中，为了安全，可将脚本保存在别处，并在apache中添加虚拟目录，进行文件浏览。
# echo "01 00  * * * root  /var/www/html/file/export.sh > /dev/null 2>&1" > /etc/cron.d/export
  
# 陕西西普数据通信股份有限公司 运行与维护部
# By：Fenei  2016年1月14日
# QQ:407603129 EMAIL:babyfenei@qq.com
# http://babyfenei.blog.51cto.com
  
#!/bin/bash
MYSQL_CMD="mysql -hDB_HOST -PDB_PORT -uDB_USER -pDB_PASSWORD"
  
rm -rf /tmp/export.log      #删除旧的下载列表文件
#select replace(title_cache,'*','') 此语句是去除图形标题中的*号 我的所有图形树中的图形都有*号 如果没有可将本语句改为 select title_cache,
select_db_sql="select replace(replace(replace(title_cache,'/','-'),' ',''),'*',''), graph_tree_items.local_graph_id from graph_tree_items left join graph_templates_graph on graph_templates_graph.local_graph_id=graph_tree_items.local_graph_id where graph_tree_items.local_graph_id <> 0 order by 'id' desc;"
echo ${select_db_sql}  | ${MYSQL_CMD} cacti  > /tmp/export.log              #查询图形树表中的图形ID非0的数据并将结果保存至下载列表                   
                                                                                 #判断是否创建成功
if [ $? -ne 0 ]
then
    echo "select databases cacti  failed ..." >>/var/log/export.log              #数据库查询失败时将添加失败日志到日志文件中
fi

mkdir -p /var/www/export
cd /var/www/export
#此命令为指定导出文件所在目录，可根据需求更改。如不指定的话会造成下载到root目录。
  
#创建以日期为名称的文件夹
mkdir -p $(date -d 1 +%Y/%m/%d/image/)
mkdir -p $(date -d 1 +%Y/%m/month/image)
mkdir -p $(date -d 1 +%Y/%m/%d/data)
mkdir -p $(date -d 1 +%Y/%m/month/data)
  
#Cacti网址阐述 这里必须在后面加'/'号 否则报错
URL="http://localhost/"
#获取当日日期  判断是否是1号
ent=`date '+%Y-%m-%d 23:59:59' --date="-1 day"`
dstt=`date '+%Y-%m-%d 00:00:00' --date="-1 day"`
mstt=`date '+%Y-%m-%d 00:00:00' --date="-1 month"`
DAY=`date +%d`
ENT=`date -d "$ent" +%s`
DSTT=`date -d "$dstt" +%s`
MSTT=`date -d "$mstt" +%s`




#删除不需要下载的图形（匹配特定字符）
sed -e '/ceshi/d;/ifAlias/d' /tmp/export.log > /tmp/export.list
 
#下载日流量图
  
cat /tmp/export.list | awk 'NR>1' | while read name id
do
    wget "${URL}graph_image.php?local_graph_id=${id}&graph_start=${DSTT}&graph_end=${ENT}" -O $(date -d 1 +%Y/%m/%d/image/)${name}.jpg
done
  
  
#下载月流量图
 
cat /tmp/export.list | awk 'NR>1' | while read name id
do
    echo "$name" | grep -q "("                                        
    if [ $? -eq 0 ]; then                                                 #判断下载文件名中是否包含()
        day=$(echo $name|grep -Po '(?<=\()[^()]+(?=\))')                      #如果()存在，则将()内的内容赋值给变量day
        if [ "$DAY" = "$day" ];then                                     #如果day也即()内的日期和当前日期一样。则下载此条数据
             wget "${URL}graph_image.php?local_graph_id=${id}&graph_start=${MSTT}&graph_end=${ENT}" -O $(date -d 1 +%Y/%m/month/image/)${name}.jpg
        fi
    elif  [ "$DAY" = 01 ];then
        wget "${URL}graph_image.php?local_graph_id=${id}&graph_start=${MSTT}&graph_end=${ENT}" -O $(date -d 1 +%Y/%m/month/image/)${name}.jpg
    fi 
done  

  
#下载日流量数据表
  
cat /tmp/export.list | awk 'NR>1' | while read name id
do
    wget "${URL}graph_xport.php?local_graph_id=${id}&graph_start=${DSTT}&graph_end=${ENT}" -O $(date -d 1 +%Y/%m/%d/data/)${name}.csv
    ssconvert $(date -d 1 +%Y/%m/%d/data/)${name}.csv $(date -d 1 +%Y/%m/%d/data/)${name}.xls
    rm -rf $(date -d 1 +%Y/%m/%d/data/)${name}.csv
done
  
  
#下载月流量数据表

cat /tmp/export.list | awk 'NR>1' | while read name id
do
    echo "$name" | grep -q "("
    if [ $? -eq 0 ]; then                                                 #判断下载文件名中是否包含()，此命令用于个别图形月流量图在指定日期下载。
        day=$(echo $name|grep -Po '(?<=\()[^()]+(?=\))')                      #如果()存在，则将()内的内容赋值给变量day
        if [ "$DAY" = "$day" ];then                                        #如果day也即()内的日期和当前日期一样。则下载此条数据
            wget "${URL}graph_xport.php?local_graph_id=${id}&graph_start=${MSTT}&graph_end=${ENT}" -O $(date -d 1 +%Y/%m/month/data/)${name}.csv
            ssconvert $(date -d 1 +%Y/%m/data/image/)${name}.csv $(date -d 1 +%Y/%m/month/data/)${name}.xls
            rm -rf $(date -d 1 +%Y/%m/month/data/)${name}.csv
        fi
    elif [ "$DAY" = 01 ];then
        wget "${URL}graph_xport.php?local_graph_id=${id}&graph_start=${MSTT}&graph_end=${ENT}" -O $(date -d 1 +%Y/%m/month/data/)${name}.csv
        ssconvert $(date -d 1 +%Y/%m/month/data/)${name}.csv $(date -d 1 +%Y/%m/month/data/)${name}.xls
        rm -rf $(date -d 1 +%Y/%m/month/data/)${name}.csv
    fi
done
