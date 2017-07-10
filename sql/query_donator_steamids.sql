SELECT distinct x.xdata_value, u.username, d.uname
FROM nukevo_bbxdata_data x 
JOIN nukevo_users u ON u.user_id = x.user_id
JOIN nukevo_donators d on d.uid = x.user_id
WHERE x.field_id = 10 AND x.xdata_value LIKE 'STEAM_%'