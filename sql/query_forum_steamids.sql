SELECT distinct x.xdata_value, u.username, u.user_rank
FROM nukevo_bbxdata_data x
JOIN nukevo_users u ON u.user_id = x.user_id
WHERE x.field_id = 10 AND x.xdata_value LIKE 'STEAM_%'
  AND u.user_rank IN (22, 25)