CREATE OR REPLACE package utl_email as

	-- allows for connection attributes to the smtp server
	type con_attribs is record
	(
		host   varchar2(255),
		port   pls_integer default 25,
		domain varchar2(255)
	);

	-- Simple table of resources for use with inline resources
	type table_of_content is table of blob index by varchar2(255);

	-- Defines information required for attachments.
	type attachment_rec is record
	(
		filename   varchar2(1024),
		mime_type  varchar2(255) default 'text/plain',
		file_data  blob
	);
	type table_of_attachments is table of attachment_rec;
	
	-- CAST_TO_BLOB
	-- This function is a utility function for converting text file content
	-- to blob content for use in attachments or inline resources.
	function cast_to_blob(p_clob in clob) return blob;

	--
	-- This version of the send method assumes the simplest method of sending email.
	-- It is assumed that plain text is being sent, but this can be changed by
	-- setting the mime type to text/html or whatever is appropriate for your needs.
	procedure send
	(
		p_con         in con_attribs,
		p_from        in varchar2,
		p_to          in varchar2,
		p_subject     in varchar2,
		p_message     in clob,
		p_mime_type   in varchar2 default 'text/plain',
		p_attachments in table_of_attachments default null
	);
	
	--
	-- This version of the send program assumes that the email is HTML based on the
	-- fact that you may be using inline resources like images. You can change the 
	-- mime type any way you choose, however, the email client may not recognise or
	-- support it.
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
	);
	
	--
	-- Deprecated! Use attachment_rec and table_of_attachments instead.
	subtype attachment_typ  is attachment_rec;
	subtype attachments_tbl is table_of_attachments;
	
	--
	-- Deprecated! Use the other send methods instead!
	procedure set_connection(p_host in varchar2, p_port in pls_integer, p_domain in varchar2);
	
	--
	-- Deprecated! Use a send method that makes use of table_of_attachments instead
	procedure send
	(
		p_sender      in varchar2,
		p_to          in varchar2,
		p_subject     in varchar2,
		p_message     in clob,
		p_mime        in varchar2 default 'text/plain',
		p_attachments in attachments_tbl
	);
	
end utl_email;
/

Show errors;
