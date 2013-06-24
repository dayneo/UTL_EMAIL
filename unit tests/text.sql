set serveroutput on size 1000000;
set timing on
declare

	l_con       utl_email.con_attribs;
	l_from      varchar2(512);
	l_to        varchar2(1024);
	l_subject   varchar2(1024); 
	l_msg       clob;

	l_gname     varchar2(32767);
	l_test_ts timestamp := systimestamp;

begin

	select lower(user) || '@' 
	                   || substr(global_name, 1, decode(dot, 0, length(global_name), dot - 1)) global_name
	  into l_gname
	  from (select global_name, instr(global_name, '.') dot from global_name);

	l_con.host   := '10.184.248.12';
	l_con.port   := 25;
	l_con.domain := 'pgwc.gov.za';
	l_to         := 'dayne.olivier@pgwc.gov.za';
	l_from       := 'dayne.olivier@pgwc.gov.za';
	l_subject    := 'Test: UTL_EMAIL text by ' || l_gname 
	                                           || ' [' || l_test_ts || ']';
	l_msg        := '0123456789' 
	             || 'abcdefghijklmnopqrstuvwxyz'
					 || 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
					 || chr(10) || chr(10) 
					 || '0123456789' 
	             || 'abcdefghijklmnopqrstuvwxyz'
					 || 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

	utl_email.send(l_con, 
						l_from, l_to, 
						l_subject, l_msg);

end;
/