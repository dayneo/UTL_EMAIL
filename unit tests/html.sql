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
	l_subject    := 'Test: UTL_EMAIL html by ' || l_gname 
	                                           || ' [' || l_test_ts || ']';
	l_msg        := '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
		<html xmlns="http://www.w3.org/1999/xhtml" >
		<head>
			 <title>Untitled Page</title>
		</head>
		<body>
			<h1>
				This is the heading</h1>
			<p>
				This is the body of the html file</p>
			<p>
				And here is a table:
			</p>
			<p>
				<table border="1">
					<caption>
						This is the caption</caption>
					<tr>
						<td style="width: 100px">
						</td>
						<td style="width: 100px">
						</td>
						<td style="width: 100px">
						</td>
					</tr>
					<tr>
						<td style="width: 100px">
						</td>
						<td style="width: 100px">
						</td>
						<td style="width: 100px">
						</td>
					</tr>
					<tr>
						<td style="width: 100px">
						</td>
						<td style="width: 100px">
						</td>
						<td style="width: 100px">
						</td>
					</tr>
				</table>
			</p>

		</body>
		</html>
	';

	utl_email.send(l_con, 
						l_from, l_to, 
						l_subject, l_msg, 'text/html');

end;
/

set timing off