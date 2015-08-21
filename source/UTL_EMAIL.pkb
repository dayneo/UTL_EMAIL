CREATE OR REPLACE package body utl_email as

	--
	-- Deprecated!
	--
	g_hostname varchar2(255) := 'smtp.server.domain';
	g_portnum  pls_integer   := 25;
	g_domain   varchar2(255) := 'pgwc.gov.za';
	--
	-- End deprecated!
	--

	type recipient_array is table of varchar2(32767);
	g_CtrLf            constant varchar2(2) := chr(13) || chr(10);

	--
	-- The inclusion of UTL_MIME procedures for internal processing
	-- without requiring the binding on UTL_MIME itself.
	--
	-- package UTL_MIME
	MIME_VERSION constant varchar2(3) := '1.0';

	subtype MIME_DOCUMENT is clob;

	-- Creates a mime document as a clob.
	procedure create_mime(p_doc in out nocopy MIME_DOCUMENT);

	-- Parses the file to produce a mime document that can be manipulated
	procedure parse_mime(p_doc in out nocopy MIME_DOCUMENT, p_file in clob);

	-- Gets and sets a mime header
	procedure set_header(p_doc in out nocopy MIME_DOCUMENT, p_name in varchar2, p_value in varchar2);
	procedure get_header(p_doc in out nocopy MIME_DOCUMENT, p_name in varchar2, p_value out varchar2);

	-- Sets the content
	procedure set_content(p_doc in out nocopy MIME_DOCUMENT, p_content in clob, p_content_type in varchar2 default null);

	-- Gets the document as a clob
	function get_clob(p_doc in out nocopy MIME_DOCUMENT) return clob;

	-- end package UTL_MIME

	-- package body UTL_MIME
	CRLF constant varchar2(2) := chr(13) || chr(10);

	procedure write_append(p_doc in out nocopy clob, p_content in clob) is

		l_sz     constant pls_integer := 32767;
		l_length pls_integer;
		l_amount pls_integer;
		l_offset pls_integer;
		l_buf    varchar2(32767);

		-- longops variables
		SECONDS_IN_DAY constant pls_integer := 24*60*60;
		l_start   date;
		l_rindex  binary_integer;
		l_slno    binary_integer;
		l_target  binary_integer;

	begin

		-- TODO: Provide longops for clobs over 32767*32=+/-1MB
		l_rindex := dbms_application_info.set_session_longops_nohint;
		l_start   := sysdate;

		l_offset  := 1;
		l_amount  := l_sz;
		l_length  := dbms_lob.getLength(p_content);
		while l_offset < l_length loop

			l_amount := least(l_sz, (l_length - l_offset)+1);
			l_buf    := dbms_lob.substr(p_content, l_amount, l_offset);
			dbms_lob.writeAppend(p_doc, l_amount, l_buf);
			l_offset := l_offset + l_amount;

			if (sysdate - l_start)*SECONDS_IN_DAY > 1 then

				dbms_application_info.set_session_longops(l_rindex, l_slno,
				                                          'UTL_MIME.WRITE_APPEND', l_target, 0,
																		l_offset, l_length,
																		'Chars sent', 'Chars');

			end if;

		end loop;

	end write_append;

	procedure write_append(p_doc in out nocopy clob, p_content in varchar2) is
	begin

		dbms_lob.writeAppend(p_doc, length(p_content), p_content);

	end write_append;

	procedure write_line(p_doc in out nocopy clob, p_content in varchar2 default '') is
	begin

		write_append(p_doc, p_content || CRLF);

	end write_line;

	function get_header_length(p_doc in out nocopy clob) return pls_integer is

		l_pos pls_integer;

	begin

		l_pos := dbms_lob.instr(p_doc, CRLF || CRLF);
		if l_pos = 0 then

			-- CRLF||CRLF not found. We assume that this is still a document
			-- in the making and that only headers exist. Thus the header length
			-- is the document length.
			return dbms_lob.getLength(p_doc);

		else

			return l_pos;

		end if;

	end get_header_length;

	-- Creates a mime document as a clob.
	procedure create_mime(p_doc in out nocopy MIME_DOCUMENT) is

		l_ver_hdr varchar2(32767);

	begin

		if p_doc is null then

			dbms_lob.createTemporary(p_doc, true);

		end if;

		write_line(p_doc, 'MIME-Version: ' || MIME_VERSION);

	end create_mime;

	procedure parse_mime(p_doc in out nocopy MIME_DOCUMENT, p_file in clob) is
	begin

		p_doc := p_file;

	end parse_mime;

	procedure set_header(p_doc in out nocopy MIME_DOCUMENT, p_name in varchar2, p_value in varchar2) is
	begin

		write_line(p_doc, p_name || ': ' || p_value);

	end set_header;

	procedure get_header(p_doc in out nocopy MIME_DOCUMENT, p_name in varchar2, p_value out varchar2) is

		l_pattern varchar2(32767);
		l_pos     pls_integer;
		l_eol_pos pls_integer;
		l_amt     pls_integer;

	begin

		l_pattern := p_name || ': ';
		l_pos := dbms_lob.instr(p_doc, l_pattern);
		if l_pos = 0
		or l_pos > get_header_length(p_doc) then

			-- header not found
			p_value := null;

		else

			l_pos     := l_pos + length(l_pattern);
			l_eol_pos := dbms_lob.instr(p_doc, CRLF, l_pos);
			l_amt     := l_eol_pos - l_pos;
			p_value   := dbms_lob.substr(p_doc, l_amt, l_pos);

		end if;

	end get_header;

	procedure set_content(p_doc in out nocopy MIME_DOCUMENT, p_content in clob, p_content_type in varchar2 default null) is
	begin

		if p_content_type is not null then

			set_header(p_doc, 'Content-Type', p_content_type);

		end if;

		write_line(p_doc, '');

		write_append(p_doc, p_content);

	end set_content;

	function get_clob(p_doc in out nocopy MIME_DOCUMENT) return clob is
	begin

		return p_doc;

	end get_clob;
	-- end UTL_MIME


	function cast_to_blob(p_clob in clob) return blob as

		buffer_size constant pls_integer := 8192; --8KB per read
		vchar       varchar2(8192);
		position    pls_integer := 1;
		output      blob;
		l_chunks    pls_integer;

		-- longops variables
		SECONDS_IN_DAY constant pls_integer := 24*60*60;
		l_start   date;
		l_rindex  binary_integer;
		l_slno    binary_integer;
		l_target  binary_integer;

	begin

		-- TODO: Provide longops for clobs over 32767*32=+/-1MB
		l_rindex := dbms_application_info.set_session_longops_nohint;
		l_start   := sysdate;

		l_chunks := ceil(dbms_lob.getLength(p_clob) / buffer_size);
		dbms_lob.createtemporary(output, true, dbms_lob.CALL);
		for i in 1..l_chunks loop

			vchar := dbms_lob.substr(p_clob, buffer_size, position);
			dbms_lob.writeappend(output, length(vchar), utl_raw.cast_to_raw(vchar));
			position := position + buffer_size;

			if (sysdate - l_start)*SECONDS_IN_DAY > 1 then

				dbms_application_info.set_session_longops(l_rindex, l_slno,
				                                          'UTL_EMAIL.CAST_TO_BLOB', l_target, 0,
																		i, l_chunks,
																		'8KB Chunks converted', 'Chunks');

			end if;

		end loop;

		return output;

	end cast_to_blob;

	procedure write_append(p_conn in out nocopy utl_smtp.connection, p_content in varchar2) is
	begin

		utl_smtp.write_data(p_conn, p_content);

	end write_append;

	procedure write_line(p_conn in out nocopy utl_smtp.connection, p_content in varchar2 default '') is
	begin

		write_append(p_conn, p_content || g_CtrLf);

	end write_line;

	procedure write_append(p_conn in out nocopy utl_smtp.connection, p_content in clob) is

		l_sz     constant pls_integer := 32767;
		l_length pls_integer;
		l_amount pls_integer;
		l_offset pls_integer;
		l_buf    varchar2(32767);

		-- longops variables
		SECONDS_IN_DAY constant pls_integer := 24*60*60;
		l_start   date;
		l_rindex  binary_integer;
		l_slno    binary_integer;
		l_target  binary_integer;

	begin

		-- Long ops entry for any append write that takes longer than
		-- 2 seconds.
		l_rindex := dbms_application_info.set_session_longops_nohint;
		l_start   := sysdate;

		l_offset  := 1;
		l_amount  := l_sz;
		l_length  := dbms_lob.getLength(p_content);
		while l_offset < l_length loop

			l_amount := least(l_sz, (l_length - l_offset)+1);
			l_buf    := dbms_lob.substr(p_content, l_amount, l_offset);
			utl_smtp.write_data(p_conn, l_buf);
			l_offset := l_offset + l_amount;

			if (sysdate - l_start)*SECONDS_IN_DAY > 2 then

				dbms_application_info.set_session_longops(l_rindex, l_slno,
				                                          'UTL_EMAIL.WRITE_APPEND', l_target, 0,
																		l_offset, l_length,
																		'Chars sent', 'Chars');

			end if;

		end loop;

	end write_append;

	procedure write_append(p_conn in out nocopy utl_smtp.connection, p_content in blob) is

		l_BASE64_LN_LENGTH constant pls_integer := 57;
		l_result           clob := empty_clob();
		l_pos              number := 1;
		l_amount           number;
		l_buffer           raw(32767);
		l_string           varchar2(32767);
		l_length           pls_integer;

		-- longops variables
		SECONDS_IN_DAY constant pls_integer := 24*60*60;
		l_start   date;
		l_rindex  binary_integer;
		l_slno    binary_integer;
		l_target  binary_integer;

	begin

		-- TODO: Provide longops for clobs over 32767*32=+/-1MB
		l_rindex := dbms_application_info.set_session_longops_nohint;
		l_start   := sysdate;

		dbms_lob.createTemporary(l_result, true, dbms_lob.CALL);
		l_length  := dbms_lob.getLength(p_content);
		while l_pos < l_length loop

			l_amount := l_BASE64_LN_LENGTH;
			dbms_lob.read(p_content, l_amount, l_pos, l_buffer);
			l_buffer := utl_encode.base64_encode(l_buffer);
			l_string := utl_raw.cast_to_varchar2(l_buffer);
			write_line(p_conn, l_string);
			l_pos    := l_pos + l_BASE64_LN_LENGTH;

			if (sysdate - l_start)*SECONDS_IN_DAY > 1 then

				dbms_application_info.set_session_longops(l_rindex, l_slno,
				                                          'UTL_EMAIL.WRITE_APPEND', l_target, 0,
																		least(l_pos, l_length), l_length,
																		'Bytes sent', 'Bytes');

			end if;

		end loop;

	end write_append;


	procedure append_inline_content(p_conn in out nocopy utl_smtp.connection, p_boundary in varchar2, p_inline_content in table_of_content) is

		l_key varchar2(32767);

	begin

		l_key := p_inline_content.first;
		while l_key is not null loop

			write_line(p_conn);
			write_line(p_conn, '--' || p_boundary);
			write_line(p_conn, 'Content-Id: <' || l_key || '>');
			write_line(p_conn, 'Content-Transfer-Encoding: base64');
			write_line(p_conn, 'Content-Disposition: inline; ');
			write_line(p_conn);
			write_append(p_conn, p_inline_content(l_key));
			write_line(p_conn);

			l_key := p_inline_content.next(l_key);

		end loop;

	end append_inline_content;


	procedure append_attachments(p_conn in out nocopy utl_smtp.connection,
	                             p_boundary in varchar2,
										  p_attachments in attachments_tbl) is

		l_cnt pls_integer;

	begin

		l_cnt := p_attachments.count;
		for i in 1..l_cnt loop

			write_line(p_conn);
			write_line(p_conn, '--' || p_boundary);
			write_line(p_conn, 'Content-Type: ' || p_attachments(i).mime_type);
			write_line(p_conn, 'Content-Transfer-Encoding: base64');
			write_line(p_conn, 'Content-Disposition: attachment; filename="' || replace(p_attachments(i).filename, '"', '""') || '"');
			write_line(p_conn);
			write_append(p_conn, p_attachments(i).file_data);
			write_line(p_conn);

		end loop;

	end append_attachments;

	-- This by no means implements the full addressing format.
	-- Returns the recipient out through p_rcpt
	-- Returns true if a recipient is found, and false if no recipient was found
	-- p_pos is returned with new string position
	function parse_rcpts(p_to   in varchar2,
	                     p_pos  in out pls_integer,
								p_rcpt out varchar2) return boolean is

		l_char    varchar2(1);
		l_capture boolean;

	begin

		-- move through the string from 1 to finish
		-- evaluate each char for /,"<
		-- begin buffer when <
		l_capture := false;
		while p_pos <= length(p_to) loop

			l_char := substr(p_to, p_pos, 1);

			if l_char = '/' then                 -- Addressing scheme parameter found

				-- If we are still here, then we are in a key/value pair
				p_pos := instr(p_to, '=', p_pos); -- skip ahead to the first = sign you can find
				if p_pos = 0 then                 -- Check that a = was found
					raise_application_error(-20000, 'Invalid address scheme.');
				end if;
				p_pos := p_pos + 1;               -- move past the =
				l_char := substr(p_to, p_pos, 1); -- get the next char
				if l_char = '"' then              -- Value is " braced, skip ahead to the next "
					p_pos := instr(p_to, '"', p_pos + 1);
					if p_pos = 0 then              -- Check that a closing " was found
						raise_application_error(-20000, 'Invalid address scheme.');
					end if;
					null;                          -- skip past the " will happen at the end of the loop
				elsif l_char != ' ' then          -- A value is found, look ahead for the next space
					p_pos := instr(p_to, ' ', p_pos);
					if p_pos = 0 then              -- Check that [space] was found
						raise_application_error(-20000, 'Invalid address scheme.');
					end if;
				end if;

				-- The current char must be a space; no longer in param, now in address
				-- Skip over space will happen at the end of the loop

			elsif l_char = '"' then              -- Addressing scheme in quotes

				p_pos := instr(p_to, '"', p_pos + 1); -- skip ahead to next quote
				if p_pos = 0 then                 -- Check that a closing " was found
					raise_application_error(-20000, 'Invalid address scheme.');
				end if;

				null;                             -- skip over the " will happen at the end of the loop

			elsif l_char = '<' then              -- found explicit address, capture forward to closing brace

				declare
					l_pos2 pls_integer;
				begin
					l_pos2 := instr(p_to, '>', p_pos);
					if l_pos2 = 0 then             -- Check that a closing > was found
						raise_application_error(-20000, 'Invalid address scheme.');
					end if;
					p_pos  := p_pos + 1;           -- Move over the >
					p_rcpt := substr(p_to, p_pos, (l_pos2 - p_pos)); -- capture to buffer
					p_pos  := l_pos2;              -- Move to the > char
					                               -- Move over the > will happen at the end of the loop
					l_capture := true;
				end;

			elsif l_char = ' ' then
				-- space detected, skip and continue
				null;

			elsif l_char = ',' then              -- The end of the current address...

				p_pos := p_pos + 1;               -- Move over the ,
				return l_capture;

			else

				p_rcpt    := p_rcpt || l_char;       -- capture char to buffer
				l_capture := true;

			end if;

			p_pos := p_pos + 1;

		end loop;

		return l_capture;

	end parse_rcpts;

	procedure send
	(
		p_con            in con_attribs,
		p_email          in clob,
		p_recipients     in out varchar2
	) is

		l_mime_doc MIME_DOCUMENT;
		l_sender   varchar2(32767);
		l_from     varchar2(32767);
		l_to       varchar2(32767);
		l_cc       varchar2(32767);
		l_bcc      varchar2(32767);
		l_recipients varchar2(32767);

		l_conn             utl_smtp.connection;
		l_boundary         varchar2(255);
		l_offset           number;
		l_saved_offset     number;
		l_ammount          number;
		l_temp             varchar2(32767);
		l_pos              pls_integer;
		l_dest             varchar2(32767);
		l_ora_instance     varchar2(32767);

	begin

		parse_mime(l_mime_doc, p_email);
		get_header(l_mime_doc, 'Sender', l_sender);
		get_header(l_mime_doc, 'From', l_from);

		-- TODO: Include a date in the submission
		-- set_header(l_mime_doc, 'Date', sysdate);

		if p_recipients is null then

			get_header(l_mime_doc, 'To', l_to);
			get_header(l_mime_doc, 'Cc', l_cc);
			get_header(l_mime_doc, 'Bcc', l_bcc);

			l_recipients := l_to || ',' || l_cc || ',' || l_bcc;
			l_recipients := rtrim(l_recipients, ',');
			p_recipients := l_recipients;

		else

			l_recipients := p_recipients;

		end if;

		-- Validation
		l_pos      := 1;
		if parse_rcpts(l_recipients, l_pos, l_dest) = false then

			raise_application_error(-20000, 'No valid recipient addresses were supplied [' || l_recipients || '].');

		end if;
		l_pos := 1; -- reset l_pos

		begin
			select global_name into l_ora_instance from global_name;
		exception
			when NO_DATA_FOUND then
				null;
		end;

		-- create l_connection to mail server.
		l_conn := utl_smtp.open_connection(p_con.host, p_con.port);

		-- TODO: Implement SMTP authentication
		--utl_smtp.command( l_mail_conn, 'AUTH LOGIN');
		--utl_smtp.command( l_mail_conn, utl_raw.cast_to_varchar2( utl_encode.base64_encode( utl_raw.cast_to_raw( 'Your Mail UserName' ))) );
		--utl_smtp.command( l_mail_conn, utl_raw.cast_to_varchar2( utl_encode.base64_encode( utl_raw.cast_to_raw( 'Your Mail Password' ))) );

		utl_smtp.helo(l_conn, p_con.domain);

		begin

			utl_smtp.mail(l_conn, nvl(l_sender, l_from));

			while parse_rcpts(l_recipients, l_pos, l_dest) loop
				utl_smtp.rcpt(l_conn, l_dest);
			end loop;

			-- Spool the mime document onto the SMTP stream
			utl_smtp.open_data(l_conn);
			begin

				-- TODO: remove BCC from the message before sending
				write_append(l_conn, l_mime_doc);

			exception
				when OTHERS then
					utl_smtp.close_data(l_conn);
					raise;
			end;

			utl_smtp.close_data(l_conn);

		exception
			when OTHERS then
				utl_smtp.quit(l_conn);
				raise;
		end;

		utl_smtp.quit(l_conn);

	end send;


	procedure send
	(
		p_con            in con_attribs,
		p_from           in varchar2,
		p_to             in varchar2,
		p_subject        in varchar2,
		p_message        in clob,
		p_mime_type      in varchar2 default 'text/html',
		p_inline_content in table_of_content,
		p_attachments    in table_of_attachments default null
	) is

		l_conn             utl_smtp.connection;
		l_boundary         varchar2(255);
		l_offset           number;
		l_saved_offset     number;
		l_ammount          number;
		l_temp             varchar2(32767);
		l_pos              pls_integer;
		l_dest             varchar2(32767);
		l_ora_instance     varchar2(32767);

	begin

		l_boundary := SYS_GUID();
		l_pos      := 1;

		-- Validation
		if parse_rcpts(p_to, l_pos, l_dest) = false then

			raise_application_error(-20000, 'No valid recipient addresses were supplied.');

		end if;
		l_pos := 1; -- reset l_pos

		begin
			select global_name into l_ora_instance from global_name;
		exception
			when NO_DATA_FOUND then
				null;
		end;

		-- create l_connection to mail server.
		l_conn := utl_smtp.open_connection(p_con.host, p_con.port);
		utl_smtp.helo(l_conn, p_con.domain);
		utl_smtp.mail(l_conn, p_from);

		while parse_rcpts(p_to, l_pos, l_dest) loop
			utl_smtp.rcpt(l_conn, l_dest);
		end loop;

		--------------------------------------------------------
		-- Compose the entire message file including attachments
		utl_smtp.open_data(l_conn);
		write_line(l_conn, 'MIME-Version: 1.0');
		write_line(l_conn, 'To: ' || p_to);
		write_line(l_conn, 'From: ' || p_from);
		write_line(l_conn, 'Subject: ' || p_subject);
		write_line(l_conn, 'Reply-To: ' || p_from);
		write_line(l_conn, 'X-Mailer: UTL_EMAIL (Oracle PL/SQL Package)');
		write_line(l_conn, 'X-Oracle-User: ' || user);
		write_line(l_conn, 'X-Oracle-Instance: ' || l_ora_instance);
		write_line(l_conn, 'Content-Type: multipart/mixed; boundary="' || l_boundary || '"');
		-- append the message body
		write_line(l_conn);
		write_line(l_conn, '--' || l_boundary);
		write_line(l_conn, 'Content-Type: ' || p_mime_type || '; charset=windows-1252');
		write_line(l_conn);
		write_append(l_conn, p_message);
		write_line(l_conn);

		-- append any inline content
		if p_inline_content.count > 0 then

			append_inline_content(l_conn, l_boundary, p_inline_content);

		end if;

		-- append the attachments
		if p_attachments is not null then

			append_attachments(l_conn, l_boundary, p_attachments);

		end if;

		-- close the message
		write_line(l_conn, '--' || l_boundary || '--');

		utl_smtp.close_data(l_conn);
		utl_smtp.quit(l_conn);
		--dbms_lob.freetemporary(l_msg);

	end send;


	procedure send
	(
		p_con         in con_attribs,
		p_from        in varchar2,
		p_to          in varchar2,
		p_subject     in varchar2,
		p_message     in clob,
		p_mime_type   in varchar2 default 'text/plain',
		p_attachments in table_of_attachments default null
	) is

		l_inline_content table_of_content;

	begin

		send(p_con,
		     p_from, p_to, p_subject, p_message, p_mime_type,
		     l_inline_content, p_attachments);

	end send;


	--
	-- Deprecated!
	--
	procedure set_connection(p_host in varchar2, p_port in pls_integer, p_domain in varchar2) is
	begin

		g_hostname := p_host;
		g_portnum  := p_port;
		g_domain   := p_domain;

	end set_connection;

	procedure send
	(
		p_sender in varchar2,
		p_to in varchar2,
		p_subject in varchar2,
		p_message in clob,
		p_mime in varchar2 default 'text/plain',
		p_attachments in attachments_tbl
	) is

		l_con            con_attribs;
		l_inline_content table_of_content;

	begin

		l_con.host   := g_hostname;
		l_con.port   := g_portnum;
		l_con.domain := g_domain;

		send(l_con,
		     p_sender, p_to, p_subject, p_message, p_mime,
		     l_inline_content, p_attachments);

	end send;

end utl_email;
/
