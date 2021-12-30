
  CREATE OR REPLACE FUNCTION "GAEBAL_UPADM"."GETCODEVALUE" (name IN varchar2) return VARCHAR2
IS
  codeValue varchar2(100);
BEGIN
  select cdvalue into codeValue from tb_code where cdname=name;
  return codeValue;
END ;
/



  CREATE OR REPLACE FUNCTION "GAEBAL_UPADM"."GETOPENUSERNAME" (userId IN varchar2) return VARCHAR2
IS
  userName varchar2(50);

BEGIN
  select DEV_NM into userName from TB_OPEN_CP where OPEN_CP_CD=userId;

  return userName;
END ;
/



  CREATE OR REPLACE FUNCTION "GAEBAL_UPADM"."GETUSEREMAIL" (userId IN varchar2) return VARCHAR2
IS
  userEmail varchar2(80);
BEGIN
  select EMAIL into userEmail from tb_user_list where user_id=userId;
  return userEmail;
END ;
/



  CREATE OR REPLACE FUNCTION "GAEBAL_UPADM"."MD5" ( key IN VARCHAR2) RETURN VARCHAR2
IS
BEGIN
    RETURN LOWER(DBMS_OBFUSCATION_TOOLKIT.MD5(INPUT => UTL_RAW.CAST_TO_RAW(key))) ;
EXCEPTION
        WHEN OTHERS THEN
                RETURN NULL;
END ;
/



  CREATE OR REPLACE FUNCTION "GAEBAL_UPADM"."GETBPNAME" (bpId IN varchar2) return VARCHAR2
IS
  bpName varchar2(100);
BEGIN
  select CO_NM into bpName from tb_partner_company where duns_number_c=bpId;
  return bpName;
END;
/



  CREATE OR REPLACE FUNCTION "GAEBAL_UPADM"."GETOPENUSERINFO" (userId IN varchar2, field IN varchar2) return VARCHAR2
IS
  data varchar2(150);
BEGIN
  select decode(upper(field), 'USER_NAME', DEV_NM,
            'RESIDENT_ID', '', 'PARTNER_ID', OPEN_CP_CD,
            'PARTNER_NAME', CP_NM,
            'EMP_NO', '', 'DEPT_NAME', CP_NM, 'EMAIL', DEV_EMAIL,
            'CELR_NUM', SUBSTR(DEV_MOBILE, 2,3)||DECODE(SUBSTR(DEV_MOBILE,5,1), '0', SUBSTR(DEV_MOBILE,6,3), SUBSTR(DEV_MOBILE,5,4))||SUBSTR(DEV_MOBILE,9,4),
            '') into data from tb_open_cp where OPEN_CP_CD=userId;
  return data;
END;
/



  CREATE OR REPLACE FUNCTION "GAEBAL_UPADM"."GETUSERHP" (userId IN varchar2) return VARCHAR2
IS
  userHp varchar2(13);
BEGIN
  select SUBSTR(CELR_NUM, 2,3)||'-'||DECODE(SUBSTR(CELR_NUM,5,1), '0', SUBSTR(CELR_NUM,6,3), SUBSTR(CELR_NUM,5,4))||'-'||SUBSTR(CELR_NUM,9,4)
    into userHp from tb_user_list where user_id=userId;
  return userHp;
END ;
/



  CREATE OR REPLACE FUNCTION "GAEBAL_UPADM"."GETUSERINFO" (userId IN varchar2, field IN varchar2) return VARCHAR2
IS
  data varchar2(150);
BEGIN
  select decode(upper(field), 'USER_NAME', USER_NAME,
            'RESIDENT_ID', RESIDENT_ID, 'PARTNER_ID', PARTNER_ID,
            'PARTNER_NAME', getBpName(PARTNER_ID),
            'EMP_NO', EMP_NO, 'DEPT_NAME', DEPT_NAME, 'EMAIL', EMAIL,
            'CELR_NUM', SUBSTR(CELR_NUM, 2,3)||DECODE(SUBSTR(CELR_NUM,5,1), '0', SUBSTR(CELR_NUM,6,3), SUBSTR(CELR_NUM,5,4))||SUBSTR(CELR_NUM,9,4),
            '') into data from tb_user_list where user_id=userId;
  return data;
END ;
/



  CREATE OR REPLACE FUNCTION "GAEBAL_UPADM"."SQUIRREL_GET_ERROR_OFFSET" (query IN varchar2) return number authid current_user
is      
  l_theCursor     integer default dbms_sql.open_cursor;      
  l_status   integer; 
begin          
	begin          
		dbms_sql.parse(  l_theCursor, query, dbms_sql.native );          
	exception                  when others then l_status:= dbms_sql.last_error_position;          
	end;          
	dbms_sql.close_cursor( l_theCursor );          
	return l_status; 
end; 
/



  CREATE OR REPLACE FUNCTION "GAEBAL_UPADM"."GETUSERNAME" (userId IN varchar2) return VARCHAR2
IS
  userName varchar2(50);
BEGIN
  select user_name into userName from tb_user_list where user_id=userId;
  return userName;
END ;
/



  CREATE OR REPLACE FUNCTION "GAEBAL_UPADM"."GET_TOKEN" (
    the_list varchar2,
    the_index number,
    delim varchar2 :=','
)
    return varchar2
is
    start_pos number;
    end_pos number;

begin
    if the_index = 1 then
        start_pos := 1;

    elsif the_index < 0 then
        start_pos := instr(the_list, delim, -1, abs(the_index)) + 1;

    else
        start_pos := instr(the_list, delim, 1, the_index - 1);

        if start_pos = 0 then
            return null;
        else
            start_pos := start_pos + length(delim);
        end if;

    end if;

    if the_index < 0 then
        end_pos := instr(the_list, delim, start_pos+1, 1);
    else
        end_pos := instr(the_list, delim, start_pos, 1);
    end if;

    if end_pos = 0 then
        return substr(the_list, start_pos);
    else
        return substr(the_list, start_pos, end_pos - start_pos);
    end if;

end get_token;
/



  CREATE OR REPLACE FUNCTION "GAEBAL_UPADM"."ADDED_SVC_OFFSET" (str IN VARCHAR2,job_cd IN VARCHAR2) RETURN VARCHAR2
IS
	base   NUMBER := 0;
	result VARCHAR2(1024);
	cd VARCHAR2(11);

BEGIN
	select decode(job_cd,'I2',0,'I3',0,'I4',305,'I5',305,'I6',610,'I7',610,'I8',915,'I9',915,10000)
into base from dual;

	if base = 10000 then
		return 'N';
	end if;

	FOR cnt IN 1..length(str) LOOP
	begin
		if substr(str,cnt,1) = '1' then
			BEGIN
				select added_svc_cd into cd from tb_added_svc where offset = (base + cnt - 1);
			EXCEPTION
       			WHEN NO_DATA_FOUND THEN
       				cd := '';

       			WHEN OTHERS THEN
					result  := SQLCODE || SQLERRM;
					RETURN result;
   			END;
			result := result || ',' || (base + cnt - 1) || '[' || cd || ']';
		end if;
	end;
   END LOOP;
   if length(result) > 0 then
    result := substr(result,2);
   else
    result := 'N';
   end if;
	RETURN result;
EXCEPTION
	WHEN OTHERS THEN
	result  := SQLCODE || SQLERRM;
		RETURN result;
END;
/



  CREATE OR REPLACE FUNCTION "GAEBAL_UPADM"."GETCODENAME" (value IN varchar2) return VARCHAR2
IS
  codeName varchar2(100);
BEGIN
  select cdname into codeName from tb_code
  where cdvalue=value;
  return codeName;
END ;
/



  CREATE OR REPLACE FUNCTION "GAEBAL_UPADM"."ISDIGIT" ( str in varchar2) return varchar2
is
	function sub_isdigit( str in varchar2 ) return varchar2
	is
	begin
		if (str is null) then
 			return 'T' ;
	 	elsif (substr(str, 1, 1) > '9') or (substr(str, 1, 1) < '0') then
	   		return 'F' ;
	 	else
	   		return sub_isdigit(substr(str, 2)) ;
	 	end if;
	end ;

	begin
 	if (str is null) then
   		return 'T' ;
 	else
   		return sub_isdigit(str);
 	end if ;
end ;
/



  CREATE OR REPLACE FUNCTION "GAEBAL_UPADM"."ISALPHA" ( str in varchar2) return varchar2
is
	function sub_isalpha( str in varchar2 ) return varchar2
	is
	begin
		if (str is null) then
 			return 'T' ;
	 	elsif (substr(str, 1, 1) > '~') or (substr(str, 1, 1) < ' ') then
			return 'F' ;
		else
	   		return sub_isalpha(substr(str, 2)) ;
	 	end if;
	end ;

	begin
 	if (str is null) then
   		return 'T' ;
 	else
   		return sub_isalpha(str);
 	end if ;
end ;
/
