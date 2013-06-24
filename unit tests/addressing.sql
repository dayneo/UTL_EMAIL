set serveroutput on size 1000000
set define off
set timing on
--exec dbms_debug_jdwp.connect_tcp('fbomb', 4119);

declare

	type address_array is table of varchar2(32767);

	l_con     utl_email.con_attribs;
	l_to      address_array;
	l_from    varchar2(32767);
	l_subject varchar2(32767);
	l_msg     varchar2(32767);

	l_test_ts timestamp := systimestamp;

begin

	l_con.host   := '10.184.248.12';
	l_con.port   := 25;
	l_con.domain := 'pgwc.gov.za';

	l_to := address_array('dayne.olivier@pgwc.gov.za',
	                      '"Dayne Olivier" dayne.olivier@pgwc.gov.za',
								 'dayne.olivier@pgwc.gov.za, dayneo@gmail.com',
								 '/fax=0866160899 <dayne.olivier@pgwc.gov.za>',
								 '/fax=0866160899 /name="Dayne Olivier" /ref= <dayne.olivier@pgwc.gov.za>',
								 '/fax=0866160899 <dayneo@gmail.com> , <dayne.olivier@pgwc.gov.za>  ,dayne.olivier@pgwc.gov.za', 
								 '"/name=Dayne Olivier ref=  id=1234 /fax=0866160899/"<npasfax@pgwc.gov.za>');

	l_from     := 'dayne.olivier@pgwc.gov.za';
	l_subject  := 'UTL_EMAIL Addressing test ' || l_test_ts;
	l_msg      := 'Testing email addressing scheme';

	for i in 1..l_to.count() loop

		begin

			utl_email.send(l_con, 
								l_from, l_to(i), 
								l_subject || ' number ' || to_char(i, '999,999'), 
								l_msg);

			dbms_output.put_line('PASS: ' || l_to(i));

		exception
			when OTHERS then
				dbms_output.put_line('FAILED! ' || l_to(i));
				dbms_output.put_line('        ' || sqlerrm);
		end;
		
	end loop;

end;
/

set timing off