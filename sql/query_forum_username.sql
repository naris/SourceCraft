SELECT distinct d.uid, d.uname FROM nukevo_donators d
 WHERE d.uname = 'TJDoobe'
   AND d.uid NOT IN (SELECT x.user_id FROM nukevo_bbxdata_data x WHERE x.field_id = 10 AND x.xdata_value LIKE 'STEAM_%')

