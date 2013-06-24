set serveroutput on size 1000000
set verify off
set feedback off

accept HOST   CHAR   DEFAULT 'mxi.pgwc.gov.za'  PROMPT 'SMTP Host: '
accept PORT   NUMBER DEFAULT 25                 PROMPT 'Port: '
accept DOMAIN CHAR   DEFAULT 'pgwc.gov.za'      PROMPT 'Domain: '
accept TOADDR CHAR   DEFAULT 'dayneo@gmail.com' PROMPT 'To: '

declare

	l_smtp_con utl_email.con_attribs;
	l_from     varchar2(32767);
	l_notify   varchar2(32767);

begin

	l_smtp_con.host   := '&HOST';
	l_smtp_con.port   := &PORT;
	l_smtp_con.domain := '&DOMAIN';

	l_from := user || '@' || l_smtp_con.domain;

	utl_email.send(l_smtp_con, 
	               l_from, '&TOADDR',
	               p_subject=>'Test: ' || l_smtp_con.host || ':' || l_smtp_con.port,
	               p_message=>to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss'));

end;
/