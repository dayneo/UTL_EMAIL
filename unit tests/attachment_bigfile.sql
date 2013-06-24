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

	l_gname     varchar2(32767);
	l_test_ts timestamp := systimestamp;

	function build_clob return clob is

		CRLF constant varchar2(2) := chr(10) || chr(13);
		l_file clob;
		l_rows pls_integer;
		l_cnt  pls_integer;

		-- longops variables
		SECONDS_IN_DAY constant pls_integer := 24*60*60;
		l_start   date;
		l_rindex  binary_integer;
		l_slno    binary_integer;
		l_target  binary_integer;

	begin

		l_file := 'This is the content of 
a plain text document. You can open this file
using notepad.';

		l_cnt  := 0;
		select count(*) 
		  into l_rows
		  from all_objects;

		l_rindex := dbms_application_info.set_session_longops_nohint;
		for rec in (select * from all_objects) loop

			dbms_lob.writeAppend(l_file, length(rec.object_name), rec.object_name);
			dbms_lob.writeAppend(l_file, length(CRLF), CRLF);

			l_cnt := l_cnt + 1;
			dbms_application_info.set_session_longops(l_rindex, l_slno, 
				                                       'BUILD_CLOB', l_target, 0, 
																	l_cnt, l_rows, 'Rows');

		end loop;

		return l_file;

	end build_clob;

begin

	l_con.host   := '10.184.248.12';
	l_con.port   := 25;
	l_con.domain := 'pgwc.gov.za';
	l_to         := 'dayne.olivier@pgwc.gov.za';
	l_from       := 'dayne.olivier@pgwc.gov.za';
	l_subject    := 'Test: UTL_EMAIL attachment_bigfile by ' || l_gname 
	                                                         || ' [' || l_test_ts || ']';
	l_msg        := 'In this test we are testing that a large attachment can be mailed '
	             || 'within a reasonable amount of time. '
					 || '0123456789' 
	             || 'abcdefghijklmnopqrstuvwxyz'
					 || 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

	l_attach := utl_email.table_of_attachments();
	l_attach.extend();	
	l_attach(l_attach.last).filename  := 'plain text attachment.txt';
	l_attach(l_attach.last).mime_type := 'text/plain';
	l_attach(l_attach.last).file_data := utl_email.cast_to_blob(build_clob());
 
	utl_email.send(l_con, 
						l_from, l_to, 
						l_subject, l_msg, 'text/plain', 
						p_attachments => l_attach);

end;
/
