set serveroutput on 1000000;
declare

	-- this example requires the use of http_filesystem table

	l_sender       varchar2(512) := 'dolivier@pgwc.gov.za';
	l_to           varchar2(1024) := 'dolivier@pgwc.gov.za';
	l_subject      varchar2(1024) := 'This is a test for utl_email'; 
	l_message      clob := 'This is a test for sending attachments

';
	l_attachments  utl_email.attachments_tbl := utl_email.attachments_tbl();

begin

	select 
		filename, 
		mime_type, 
		blob_content 
	bulk collect into l_attachments
	from
		http_filesystem
	where
		doc_size > 10000
		and rownum <= 4;
 
	utl_email.send(l_sender, l_to, l_subject, l_message, p_attachments => l_attachments);

end;
/