"Zunburst Memstat Downloader (User 2 TCD/Report)
"""
"This report extracts the executed transactions and reports from the memory statistic on user level.
"Please note, you don't need to label the parameters and/or title. These are filled automatically.
"Hint: Just create a new transaction for this report (SE93) - 'report transaction' to use it in production.
"""
"V1.0 - 19th of August 2018
"Author: Sebastian Reiter - contact@zunburst.com
"""
"Copyright © 2018 Zunburst GmbH, https://zunburst.com
"
"Licensed under the Apache License, Version 2.0 (the "License");
"you may not use this file except in compliance with the License.
"You may obtain a copy of the License at
"
"    http://www.apache.org/licenses/LICENSE-2.0
"
"Unless required by applicable law or agreed to in writing, software
"distributed under the License is distributed on an "AS IS" BASIS,
"WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
"See the License for the specific language governing permissions and
"limitations under the License.
"""
REPORT /ZUNBURST/MEMSTAT_D_USR2TR.

TABLES SSCRFIELDS.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(23) ttime_l FOR FIELD tmonth.
PARAMETERS: tmonth(2) TYPE C,
            tyear(4) TYPE C.
SELECTION-SCREEN COMMENT 35(10) tlen_l FOR FIELD tlen.
PARAMETERS: tlen(2) TYPE C DEFAULT '03'.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN SKIP.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(23) tfile_l FOR FIELD tfile.
PARAMETERS: tfile TYPE rlgrap-filename.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(23) tdeli_l FOR FIELD tdeli.
PARAMETERS: tdeli(4) TYPE C DEFAULT ','.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN SKIP.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) ttcd_o_l FOR FIELD ttcd_o.
PARAMETERS: ttcd_o AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 5(23) tget_d_l FOR FIELD tget_d.
PARAMETERS: tget_d AS CHECKBOX DEFAULT ''.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN SKIP.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON 3(16) ex_strt USER-COMMAND com1.
SELECTION-SCREEN END OF LINE.

DATA tucomm TYPE TABLE OF SY-UCOMM.

INITIALIZATION.

CLEAR tucomm.
APPEND 'ONLI' TO tucomm.
CALL FUNCTION 'RS_SET_SELSCREEN_STATUS'
EXPORTING
  P_STATUS = '%_00'
  P_PROGRAM = SY-REPID
TABLES
  P_EXCLUDE = tucomm.

SY-TITLE = 'Zunburst Memstat Downloader (User 2 TCD/Report)'.

ex_strt = 'Start Extraction'.

ttime_l = 'Start from (MM/YYYY)'.
tfile_l = 'Extract Target (.csv)'.
tlen_l = '  for (MM)'.

tdeli_l = 'Delimiter'.

ttcd_o_l = 'Get Only Transactions'.
tget_d_l = 'Add TCD/Report Desc.'.

IF SY-DATUM+4(2) - 2 GT 0.
    tmonth = SY-DATUM+4(2) - 2.
    IF tmonth LT 10.
        CONCATENATE '0' tmonth INTO tmonth.
    ENDIF.
    tyear = SY-DATUM+0(4).
ELSE.
    tmonth = SY-DATUM+4(2) - 2 + 12.
    tyear = SY-DATUM+0(4) - 1.
ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR tfile.
  DATA: tgt_path TYPE STRING,
        tgt_filename TYPE STRING,
        tgt_fullpath TYPE STRING,
        this_default_file_name TYPE STRING.

  CONCATENATE SY-DATUM+0(4) SY-DATUM+4(2) SY-DATUM+6(2) '_zbrst_memst_ext_from' tmonth tyear '_for' tlen 'mm_' SY-SYSID  INTO this_default_file_name.

  CALL METHOD CL_GUI_FRONTEND_SERVICES=>FILE_SAVE_DIALOG
    EXPORTING
      DEFAULT_EXTENSION = 'CSV'
      FILE_FILTER = '*.CSV'
      DEFAULT_FILE_NAME = this_default_file_name
    CHANGING
      FILENAME = tgt_filename
      PATH = tgt_path
      FULLPATH = tgt_fullpath.
 tfile = tgt_fullpath.

AT SELECTION-SCREEN.
  CASE SSCRFIELDS.
    WHEN 'COM1'.
      DATA: cfile TYPE STRING.
      cfile = tfile.

      IF tmonth IS INITIAL OR tyear IS INITIAL.
        SET CURSOR FIELD 'TMONTH'.
        message 'Start (MM/YYYY) can not be empty.' type 'E'.
      ENDIF.

      IF tlen IS INITIAL.
        SET CURSOR FIELD 'TLEN'.
        message 'Length (MM) can not be empty.' type 'E'.
      ENDIF.

      IF cfile IS INITIAL.
         SET CURSOR FIELD 'TFILE'.
         message 'Extract Target can not be empty.' type 'E'.
      ENDIF.

      IF tdeli IS INITIAL.
         SET CURSOR FIELD 'TDELI'.
         message 'Delimiter can not be empty.' type 'E'.
      ENDIF.

      DATA: is_num TYPE STRING.
      is_num = '0123456789'.

      IF tmonth CN is_num OR tyear CN is_num.
        SET CURSOR FIELD 'TMONTH'.
        message 'Start (MM/YYYY) has to be numeric.' type 'E'.
      ENDIF.
      IF tlen CN is_num.
        SET CURSOR FIELD 'TLEN'.
        message 'Length (MM) has to be numeric.' type 'E'.
      ENDIF.

      DATA: date_san_set TYPE STRING,
            date_san_now TYPE STRING.

      CONCATENATE tyear tmonth INTO date_san_set.
      CONCATENATE SY-DATUM+0(4) SY-DATUM+4(2) INTO date_san_now.

      IF date_san_set GT date_san_now.
        SET CURSOR FIELD 'TMONTH'.
        message 'I can not see the future(...yet).' type 'E'.
      ENDIF.

      DATA: clen TYPE I,
            cmonth TYPE I,
            cyear TYPE I.
      clen = tlen.
      cmonth = tmonth.
      cyear = tyear.

      IF clen EQ 0.
        SET CURSOR FIELD 'TLEN'.
        message 'Length (MM) can not be zero.' type 'E'.
      ENDIF.

      IF cmonth GT 12.
        SET CURSOR FIELD 'TMONTH'.
        message 'A year has twelve months.' type 'E'.
      ENDIF.

      TYPES: BEGIN OF typ_tcd_des,
              tcode TYPE STRING,
              ttext TYPE STRING,
             END OF typ_tcd_des,
             BEGIN OF typ_rep_des,
              name TYPE STRING,
              text TYPE STRING,
             END OF typ_rep_des.

      DATA: tbl_typ_tcd_des TYPE HASHED TABLE OF typ_tcd_des WITH UNIQUE KEY tcode,
            tbl_typ_rep_des TYPE HASHED TABLE OF typ_rep_des WITH UNIQUE KEY name.

      IF tget_d EQ 'X'.
        SELECT TCODE TTEXT FROM TSTCT INTO TABLE tbl_typ_tcd_des WHERE SPRSL EQ 'EN'.
        SELECT NAME TEXT FROM TRDIRT INTO TABLE tbl_typ_rep_des WHERE SPRSL EQ 'EN'.
      ENDIF.

      DATA: res_tab TYPE TABLE OF STRING,
            res_line TYPE STRING,
            res_count TYPE I.
      res_count = 0.

      IF tget_d EQ 'X'.
        CONCATENATE 'PERIOD' tdeli 'USER-ID' tdeli 'TCD/REPORT' tdeli 'ENT TYPE' tdeli 'TCD/REPORT DESC' INTO res_line.
      ELSE.
        CONCATENATE 'PERIOD' tdeli 'USER-ID' tdeli 'TCD/REPORT' tdeli 'ENT TYPE' INTO res_line.
      ENDIF.
      APPEND res_line TO res_tab.

      WHILE clen NE 0.

        DATA: vextr_date TYPE STRING,
              tmp_month TYPE STRING,
              tmp_year TYPE STRING.
        tmp_month = cmonth.
        tmp_year = cyear.
        CONDENSE tmp_month.
        CONDENSE tmp_year.

        IF cmonth LT 10.
            CONCATENATE tmp_year '0' tmp_month '01' INTO vextr_date.
        ELSE.
            CONCATENATE tmp_year tmp_month '01' INTO vextr_date.
        ENDIF.

        DATA: t_res_usertcode TYPE TABLE OF SWNCAGGUSERTCODE,
              t_sys TYPE SWNCSYSID,
              cextr_date TYPE SY-DATUM.
        cextr_date = vextr_date.

        FIELD-SYMBOLS: <taline> LIKE LINE OF t_res_usertcode.

        t_sys = SY-SYSID.

        CALL FUNCTION 'SWNC_COLLECTOR_GET_AGGREGATES'
          EXPORTING
            COMPONENT = 'TOTAL'
            ASSIGNDSYS = t_sys
            PERIODTYPE = 'M'
            PERIODSTRT = cextr_date
            SUMMARY_ONLY = ' '
            STORAGE_TYPE = ' '
            FACTOR = 1000
          TABLES
            USERTCODE = t_res_usertcode
          EXCEPTIONS
            NO_DATA_FOUND = 1.

        IF cmonth EQ 12.
            ADD 1 TO cyear.
            cmonth = 1.
        ELSE.
            ADD 1 TO cmonth.
        ENDIF.

        SUBTRACT 1 FROM clen.

        IF SY-SUBRC <> 0.
            CONTINUE.
        ENDIF.

        LOOP AT t_res_usertcode ASSIGNING <taline>.
            DATA: tmp_usr TYPE STRING,
                  tmp_reptcd TYPE STRING,
                  tmp_enttyp TYPE STRING.

            tmp_usr = <taline>-ACCOUNT.
            CONDENSE tmp_usr.

            tmp_reptcd = <taline>-ENTRY_ID+0(40).
            tmp_enttyp = <taline>-ENTRY_ID+72(1).
            CONDENSE tmp_reptcd.
            CONDENSE tmp_enttyp.

            IF ttcd_o EQ 'X' AND tmp_enttyp EQ 'R'.
                CONTINUE.
            ENDIF.

            DATA: tmp_reptcd_desc TYPE STRING,
                  lin_typ_tcd_des TYPE typ_tcd_des,
                  lin_typ_rep_des TYPE typ_rep_des.

            CLEAR res_line.

            IF tget_d EQ 'X'.
                IF tmp_enttyp EQ 'T'.
                    READ TABLE tbl_typ_tcd_des INTO lin_typ_tcd_des WITH KEY tcode = tmp_reptcd.
                    IF SY-SUBRC = 0.
                        tmp_reptcd_desc = lin_typ_tcd_des-ttext.
                    ENDIF.
                ENDIF.
                IF tmp_enttyp EQ 'R'.
                    READ TABLE tbl_typ_rep_des INTO lin_typ_rep_des WITH KEY name = tmp_reptcd.
                    IF SY-SUBRC = 0.
                        tmp_reptcd_desc = lin_typ_rep_des-text.
                    ENDIF.
                ENDIF.

                CONCATENATE vextr_date+0(6) tdeli tmp_usr tdeli tmp_reptcd tdeli tmp_enttyp tdeli tmp_reptcd_desc INTO res_line.
            ELSE.
                CONCATENATE vextr_date+0(6) tdeli tmp_usr tdeli tmp_reptcd tdeli tmp_enttyp INTO res_line.
            ENDIF.

            APPEND res_line TO res_tab.

            ADD 1 TO res_count.
        ENDLOOP.

      ENDWHILE.

      CALL FUNCTION 'GUI_DOWNLOAD'
        EXPORTING
          FILENAME = cfile
          CODEPAGE = '4110' "utf-8
        TABLES
          DATA_TAB = res_tab
        EXCEPTIONS
          FILE_WRITE_ERROR = 1
          DP_OUT_OF_MEMORY = 2
          DISK_FULL = 3
          UNKNOWN_ERROR = 4.

      IF SY-SUBRC <> 0.
        message 'Error while exporting.' type 'E'.
      ENDIF.

      DATA: res_mess TYPE STRING,
            cres_count TYPE STRING.
      cres_count = res_count.
      CONDENSE cres_count.

      CONCATENATE 'Exported' cres_count 'rows.' INTO res_mess SEPARATED BY space.
      message res_mess type 'S'.
  ENDCASE.
