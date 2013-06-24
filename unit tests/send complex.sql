set serveroutput on 1000000;
declare

	-- this example requires the use of http_filesystem table

	l_sender       varchar2(512)  := 'dayne.olivier@pgwc.gov.za';
	l_to           varchar2(1024) := 'dayne.olivier@pgwc.gov.za';
	l_subject      varchar2(1024) := 'This is a test for utl_email'; 
	l_message      clob := '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" >
<head>
    <title>Untitled Page</title>
</head>
<body>
	This here is an HTML page.<br />
	The source is done in HTML and here is a <a href="http://www.google.com">link</a><br />
	Also, here is a table<br />
	<table>
		<tr>
			<td style="width: 208px">
				cell1</td>
			<td style="width: 219px">
				cell2</td>
			<td style="width: 100px">
				cell 3</td>
		</tr>
		<tr>
			<td style="width: 208px">
				row2</td>
			<td style="width: 219px">
			</td>
			<td style="width: 100px">
			</td>
		</tr>
		<tr>
			<td style="width: 208px; height: 84px">
				row3</td>
			<td style="width: 219px; height: 84px">
			</td>
			<td style="width: 100px; height: 84px">
				x</td>
		</tr>
	</table>

</body>
</html>
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
 
	utl_email.send(l_sender, l_to, l_subject, l_message, 'text/html', p_attachments => l_attachments);

end;
/