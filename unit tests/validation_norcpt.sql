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

begin

	l_con.host   := 'outmail.capegateway.gov.za';
	l_con.port   := 25;
	l_con.domain := 'pgwc.gov.za';
	l_from       := 'dayne.olivier@pgwc.gov.za';
	l_subject    := 'UTL_EMAIL test: attachment_single';
	l_msg        := 'Testing email addressing scheme ' || sysdate;

	utl_email.send(l_con, 
						l_from, l_to, 
						l_subject, l_msg);

end;
/

set timing off