import db

def delete_entry(table,field,value):
	try:
		dbconn = db.connect_db(db.host, db.user, db.passwd, db.db)
		cur = dbconn.cursor()
		cur.execute("DELETE FROM %s WHERE %s ='%s'" % (table,field,value))
		
		dbconn.commit()
		dbconn.close()
	except:
        	return 0



with open('/home/jisyrijo/JaldeeWS1.3/you.never.wait/DynamicTDD/numbers1.txt','r') as f:
	for r in f:
		r = r.rstrip('\n')
		print (r)
		uid = db.get_id(str(r))
		aid = db.get_acc_id(str(r))
		print (uid) 
		print (aid)
		db.delete_search(aid)
		db.delete_sequence_generator(aid)
		db.delete_ML_table(aid)
		delete_entry('favorite_provider_tbl','account_id',aid)
		delete_entry('favorite_provider_tbl','cust_id',uid)
		delete_entry('wl_state_tbl','account',aid)
		delete_entry('wl_state_tbl','created_by',uid)
		delete_entry('wl_provider_note_tbl','account',aid)
		delete_entry('wl_rating_tbl','account',aid)
		delete_entry('wl_history_tbl','account',aid)
		delete_entry('wl_history_tbl','created_by',uid)
		delete_entry('wl_history_tbl','consumer_id',uid)
		delete_entry('wl_cache_tbl','account',aid)
		delete_entry('wl_cache_tbl','created_by',uid)
		delete_entry('wl_cache_tbl','consumer_id',uid)
		db.delete_queue_service(aid)
		db.delete_queue_stats_table(aid)
		db.delete_donation_service(aid)
		db.delete_schedule_service(aid)
		delete_entry('queue_tbl','account',aid)
		delete_entry('service_tbl','account',aid) 
		delete_entry('acc_contact_info_tbl','acc_info_id',aid)  
		delete_entry('account_info_tbl','id',aid) 
		delete_entry('account_license_tbl','account',aid)
		delete_entry('account_matrix_usage_tbl','id',aid)
		delete_entry('account_settings_tbl','account',aid)
		delete_entry('account_payment_settings_tbl','id',aid)
		delete_entry('wl_settings_tbl','id',aid)
		delete_entry('acc_lic_subscription_tbl','id',aid)
		delete_entry('account_tbl','id',aid)
		delete_entry('local_user_tbl','account',aid)
		delete_entry('login_history_tbl','user_id',aid)
		delete_entry('audit_log_tbl','account',aid)
		delete_entry('consumer_msg_tbl','created_by',uid)
		delete_entry('consumer_msg_tbl','modified_by',uid)
		delete_entry('consumer_msg_tbl','id',uid)
		delete_entry('provider_msg_tbl','account',aid)	
		delete_entry('bill_tbl','account',aid)
		delete_entry('bill_tbl','consumer_id',uid)
		delete_entry('consumer_tbl','account',aid)
		delete_entry('consumer_tbl','id',uid)
		delete_entry('user_profile_tbl','created_by',aid)
		delete_entry('login_tbl','id',uid)
		delete_entry('login_history_tbl','user_id',uid)
		delete_entry('user_tbl','id',uid)	
		delete_entry('item_tbl','account',aid)
		delete_entry('acc_discount_tbl','account',aid)
		delete_entry('alert_tbl','account',aid)
		delete_entry('image_info_tbl','id',aid)
		delete_entry('location_tbl','account',aid)	
		delete_entry('acc_coupon_tbl','account',aid)
		delete_entry('adword_tbl','account',aid)
		delete_entry('invoice_details_tbl','created_by',uid)
		delete_entry('invoice_tbl','account',aid)
		delete_entry('acc_credit_debit_tbl','account',aid)
		delete_entry('label_tbl','account',aid)
		delete_entry('account_rating_tbl','account',aid)
		delete_entry('holidays_tbl','account',aid)
		delete_entry('branch_tbl','id',aid)
		delete_entry('item_unit_tbl','created_by',uid)
		delete_entry('bill_tbl','account',aid)
		delete_entry('ynw_txn_tbl','created_by',uid)
		delete_entry('service_tbl','account',aid)
		delete_entry('payment_tbl','account_id',aid)   
		delete_entry('reimburse_payment_tbl','account',1)  
		delete_entry('reimburse_invoice_tbl','account',aid) 
		delete_entry('bill_tbl','account_id',aid)
		delete_entry('jc_provider_stats_tbl','provider_id',aid)
		delete_entry('jc_live_stat_tbl','provider_id',aid)
		delete_entry('provider_jc_tbl','account_id',aid)
		delete_entry('pos_settings_tbl','account',aid)
		delete_entry('notification_settings_tbl','account',aid)
		delete_entry('jdn_disc_tbl','id',aid)