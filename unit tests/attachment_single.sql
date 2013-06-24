set serveroutput on size 1000000;
set verify off
set timing on

declare

	l_con     utl_email.con_attribs;
	l_to      varchar2(32767);
	l_from    varchar2(32767);
	l_subject varchar2(32767);
	l_msg     varchar2(32767);
	l_attach  utl_email.table_of_attachments;

	l_test_ts timestamp := systimestamp;

begin

	l_con.host   := '10.184.248.25';
	l_con.port   := 25;
	l_con.domain := 'pgwc.gov.za';
	l_to         := 'dayne.olivier@pgwc.gov.za';
	l_from       := 'dayne.olivier@pgwc.gov.za';
	l_subject    := 'UTL_EMAIL attachment_single test @ ' || l_test_ts;
	l_msg        := 'Testing email addressing scheme';

	l_attach := utl_email.table_of_attachments();
	l_attach.extend();	
	l_attach(l_attach.last).filename  := 'plain text attachment.txt';
	l_attach(l_attach.last).mime_type := 'text/plain';
	l_attach(l_attach.last).file_data := utl_email.cast_to_blob('This is the content of 
a plain text document. You can open this file
using notepad.');
 
	utl_email.send(l_con, 
						l_from, l_to, 
						l_subject, l_msg, 'text/plain', 
						p_attachments => l_attach);

end;
/
