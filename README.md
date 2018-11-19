
#### 功能介绍
1.本脚本自动安装cacti0.8.8h版本

2.自动安装cacti0.8.8h、rrdtool1.4.9、spine0.8.8h到系统

3.本脚本运行在centos6.5-6.8下

4.本脚本自动添加中文微软雅黑字体到centos系统中,rrdtool及cacti默认支持中文

5.本脚本开头有自定义rrdtool水印变量,可根据需求更改

6.本脚本自动添加图形导出脚本,自动按照日期每日、每天导出图形树内所有图形和数据

7.本脚本自动添加数据库备份脚本

8.本脚本自动下载目前已验证可以正常使用的cacti0.8.8h版本下的插件

9.本脚本自动更改graph_xport.php文件编码,解决中文标题图形导出数据的乱码问题

10.本脚本自动修改某些常用settings设置项

11.本脚本自动安装cacti后需监控cacti本地服务器的,需修改device中localhost的snmp监控方式才可正常监控

12.本脚本增加cacti按照Base_value的值(1000或1024),对流量图按照1000或者1024进行计算，包括95值和带宽总计。
 
---

#### 使用方法 ###

```git clone https://github.com/babyfenei/cacti-autoinstall-centos6-0.8.8h.git```

```cd cacti-autoinstall-centos6-0.8.8h && bash start.sh```

---

#### 示例图片

![cacti_backup_export](/container-files/pic/cacti_console.png)
![cacti_plugin_management](/container-files/pic/cacti_plugin_management.png)
![cacti_settings](/container-files/pic/cacti_settings.png)
![cacti_thold](/container-files/pic/cacti_thold.png)
![cacti_graph](/container-files/pic/cacti_graph.png)
![cacti_syslog_viewer](/container-files/pic/cacti_syslog_viewer.png)
![cacti_backup_export](/container-files/pic/cacti_backup_export.png)
![cacti_export](/container-files/pic/cacti_export.png)
![rrdtool_logo](/container-files/pic/rrdtool_logo.png)
![thold_wechat](/container-files/pic/thold_wechat.png)
![cacti_1024](/container-files/pic/cacti_1024.png)



