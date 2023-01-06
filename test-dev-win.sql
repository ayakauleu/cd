SET search_path = pg_catalog;

-- DEPCY: This FUNCTION depends on the COLUMN: kp_core.user_.email

DROP FUNCTION pstp_o_user.user_edit(p_request jsonb);

-- DEPCY: This FUNCTION depends on the COLUMN: kp_core.user_.email

DROP FUNCTION pstp_o_user.password_reset_free(p_request jsonb);

-- DEPCY: This FUNCTION depends on the COLUMN: kp_core.user_.email

DROP FUNCTION pstp_o_message.token_verify(p_token text, OUT result utl_core.call_result, OUT token_info kp_core.token_session);

-- DEPCY: This PROCEDURE depends on the COLUMN: kp_core.user_.email

DROP PROCEDURE obj_mgr.monitor_client();

-- DEPCY: This PROCEDURE depends on the COLUMN: kp_core.user_.email

DROP PROCEDURE obj_mgr.audit_client_action();

-- DEPCY: This FUNCTION depends on the COLUMN: kp_core.user_.email

DROP FUNCTION kp_core.user_create(client_name character varying, client_login character varying, client_password character varying, client_phone_number character varying, client_type_id bigint, client_supplier_id bigint, client_blocked boolean, client_email character varying, current_login character varying, p_role_id bigint, p_creation_method_id integer);

-- DEPCY: This FUNCTION depends on the COLUMN: kp_core.user_.email

DROP FUNCTION kp_core.check_user(p_login text, p_ip_address text);

-- DEPCY: This FUNCTION depends on the COLUMN: kp_core.user_.email

DROP FUNCTION kp_core.user_reset_password(p_login text);

-- DEPCY: This VIEW depends on the COLUMN: kp_core.user_.email

DROP VIEW kp_api_ui.user_type;

-- DEPCY: This TRIGGER depends on the COLUMN: kp_core.user_.email

DROP TRIGGER crud_user_ ON kp_api_ui.user_;

-- DEPCY: This FUNCTION depends on the COLUMN: kp_core.user_.email

DROP FUNCTION kp_api_ui.crud_user_();

-- DEPCY: This VIEW depends on the COLUMN: kp_core.user_.email

DROP VIEW kp_api_ui.user_;

-- DEPCY: This FUNCTION depends on the COLUMN: kp_core.user_.email

DROP FUNCTION kp_api_ui.server_message_create(p_date_create timestamp without time zone, p_date_send timestamp without time zone, p_heading text, p_message text, p_suppliers bigint[], p_sending_immediately boolean);

-- DEPCY: This FUNCTION depends on the COLUMN: kp_core.user_.email

DROP FUNCTION kp_api_ui.server_message_update(p_message_id bigint, p_date_send timestamp without time zone, p_heading text, p_message text, p_suppliers bigint[], p_sending_immediately boolean);

ALTER TABLE kp_core.user_
	ALTER COLUMN email TYPE character varying(90) USING email::character varying(90); /* ТИП колонки изменился - Таблица: kp_core.user_ оригинал: character varying(50) новый: character varying(90) */

CREATE OR REPLACE FUNCTION pstp_o_user.login_reset_free(p_request jsonb) RETURNS json
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_phone TEXT;
    v_email TEXT;
    v_db_user_id BIGINT;
    v_db_login TEXT;
BEGIN
    v_phone := utl_json.get(p_request, '$.PhoneNumber', TRUE);
    v_email := utl_json.get(p_request, '$.EMail', TRUE);

    BEGIN
        SELECT user_id, login
        INTO STRICT v_db_user_id, v_db_login
        FROM kp_core.user_
        WHERE phone_number = v_phone
          AND LOWER(email) = LOWER(v_email);
    EXCEPTION
        WHEN OTHERS THEN
            CALL err_mgr.raise_error('User not found', 'e_no_data', 409);
    END;
    --Сброс пароля
    PERFORM kp_core.user_reset_password(v_db_login);

    RETURN '{}'::json;
END
$_$;

ALTER FUNCTION pstp_o_user.login_reset_free(p_request jsonb) OWNER TO postgres;

REVOKE ALL ON FUNCTION pstp_o_user.login_reset_free(p_request jsonb) FROM PUBLIC;

CREATE OR REPLACE FUNCTION kp_api_ui.crud_supplier() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_user_id     NUMERIC(19) := CURRENT_SETTING('kp_context.user_id', TRUE) :: NUMERIC(19);
    v_abon_count  BIGINT;
    v_new_abonent BOOLEAN;

BEGIN
    PERFORM kp_api_ui.ui_dml_before();

    SELECT tg_op IN ('INSERT', 'UPDATE') AND COUNT(*) = 0
    INTO v_new_abonent
    FROM kp_core.abonent
    WHERE abonent = new.abonent;
    new.ftp_port := coalesce(new.ftp_port, 21);
    IF v_new_abonent THEN
        --Добавляем абонента
        INSERT INTO kp_core.abonent (abonent, abonent_name, cript_type, date_change, user_id, character_set, ref_count,
                                     ftp_server, ftp_port, ftp_login, ftp_password, ftp_timeout, ftp_dir_in,
                                     ftp_dir_in_bak, ftp_dir_in_err, ftp_dir_out, ftp_copy_exp_dir, transport_type,
                                     ip_address, disp_port)
        VALUES (new.abonent, new.supplier_name, 1, kp_core.current_server_timestamp(), v_user_id, 1, 0,
                new.ftp_server, new.ftp_port, new.ftp_login, new.ftp_password,
                20, 'ftp://out', 'ftp://out/bak', 'ftp://out/bak', 'ftp://in', 'ftp://in/copy', 'F', new.ftp_server,
                new.ftp_port);

        INSERT INTO kp_core.abonent_message_type (abonent, mti, direction, status)
        VALUES (new.abonent, -21000, 0, 1)
             , (new.abonent, -52000, 1, 1)
             , (new.abonent, -52100, 1, 1)
             , (new.abonent, -52200, 0, 1)
             , (new.abonent, -52300, 0, 1)
             , (new.abonent, -52400, 0, 1);
    ELSE
        --Изменяем абонента
--        IF COALESCE(old.abonent, '') != COALESCE(new.abonent, '') THEN
        --             DELETE FROM kp_core.abonent_message_type amt WHERE amt.abonent = old.abonent;
--             UPDATE kp_core.abonent
--             SET abonent = new.abonent
--             WHERE abonent = old.abonent;
--            INSERT INTO kp_core.abonent_message_type (abonent, mti, direction, status)
--            VALUES (new.abonent, -21000, 0, 1);
--        END IF;

        UPDATE kp_core.abonent a
        SET ftp_login    = new.ftp_login,
            ftp_password = new.ftp_password,
            ftp_server   = new.ftp_server,
            disp_port    = new.ftp_port,
            ip_address   = new.ftp_server
        WHERE a.abonent = new.abonent;
    END IF;

    IF (tg_op = 'INSERT') THEN
        --Добавляем поставщика с этим абонентом
        INSERT INTO kp_core.supplier (supplier_name, enabled, supplier_domicile, supplier_unp, manager_post,
                                      manager_name, bookkeeper_name, supplier_shortname, out_supplier_code,
                                      email, abonent, bank_id, account, contract, date_change)
        VALUES (new.supplier_name, COALESCE(new.enabled, kp_core.get_field_def('supplier', 'enabled')::BOOLEAN),
                new.supplier_domicile, new.supplier_unp, new.manager_post, new.manager_name, new.bookkeeper_name,
                new.supplier_shortname,
                new.out_supplier_code, new.email, new.abonent, new.bank_id, new.account, new.contract,
                COALESCE(new.date_change::TIMESTAMP, kp_core.current_server_timestamp()))
        RETURNING supplier_id, date_change INTO new.supplier_id, new.date_change;
--        PERFORM obj_mgr.audit(16, 'Создан производитель услуг ' || new.supplier_name, '1');
    ELSIF (tg_op = 'UPDATE') THEN
        --Изменяем поставщика
        UPDATE kp_core.supplier
        SET supplier_name      = new.supplier_name,
            enabled            = COALESCE(new.enabled, kp_core.get_field_def('supplier', 'enabled')::BOOLEAN),
            supplier_domicile  = new.supplier_domicile,
            supplier_unp       = new.supplier_unp,
            manager_post       = new.manager_post,
            manager_name       = new.manager_name,
            bookkeeper_name    = new.bookkeeper_name,
            supplier_shortname = new.supplier_shortname,
            out_supplier_code  = new.out_supplier_code,
            email              = new.email,
            abonent            = new.abonent,
            bank_id            = nullif(new.bank_id, -1),
            account            = new.account,
            contract           = new.contract,
            date_change        = kp_core.current_server_timestamp()
        WHERE supplier_id = old.supplier_id
        RETURNING supplier_id INTO new.supplier_id;

        IF old.enabled AND NOT new.enabled THEN
            --Отключая организацию
            UPDATE kp_core.user_ SET blocked = true WHERE personal_num = old.supplier_id::TEXT and blocked = false;
        END IF;

        IF not old.enabled AND new.enabled THEN
            --Включая организацию
            UPDATE kp_core.user_ SET blocked = false WHERE personal_num = old.supplier_id::TEXT and type_id = 3 and blocked = true;
        END IF;

        select bank_id, bank_bic into new.bank_id, new.bank_bic from kp_api_ui.supplier where supplier_id = new.supplier_id;

--        PERFORM obj_mgr.audit(17, 'Изменение поставщика услуг с id=' || new.supplier_id::TEXT);

    ELSIF (tg_op = 'DELETE') THEN
        --Переход от проверок в коде на констрейнты и детализация

--         SELECT COUNT(1)
--         INTO v_count_claim_paym
--         FROM (SELECT 1
--               FROM kp_core.claim c
--               WHERE c.supplier_account_id IN (SELECT sa.supplier_account_id
--                                               FROM kp_core.supplier_account sa
--                                               WHERE sa.supplier_id = old.supplier_id)
--               UNION
--               SELECT 1
--               FROM kp_core.payment p
--               WHERE p.supplier_account_id IN (SELECT sa.supplier_account_id
--                                               FROM kp_core.supplier_account sa
--                                               WHERE sa.supplier_id = old.supplier_id)
--              ) c;
--
--         IF v_count_claim_paym != 0 THEN
--             CALL err_mgr.raise_error('There are requirements and payments for the manufacturer''s services.',
--                                      'e_not_found', 404);
--         ELSE
--             BEGIN
--                 DELETE FROM kp_core.supplier s WHERE s.supplier_id = old.supplier_id;
--             EXCEPTION
--                 WHEN FOREIGN_KEY_VIOLATION THEN
--                     CALL err_mgr.raise_error('There are requirements and payments for the manufacturer''s services.',
--                                              'e_not_found', 404);
--             END;
--             DELETE FROM kp_core.abonent a WHERE a.abonent = old.abonent;
--             DELETE FROM kp_core.abonent_message_type amt WHERE amt.abonent = old.abonent;
--         END IF;
        DELETE FROM kp_core.supplier WHERE supplier_id = old.supplier_id;
--        PERFORM obj_mgr.audit(18, 'Удален производитель услуг ' || old.supplier_shortname);
    END IF;

    SELECT COUNT(*) INTO v_abon_count FROM kp_core.supplier WHERE abonent = new.abonent;
    IF v_abon_count > 1 THEN
        CALL err_mgr.raise_error('Such a subscriber already exists');
    END IF;

    RETURN CASE tg_op WHEN 'DELETE' THEN old ELSE new END;
EXCEPTION
    WHEN OTHERS THEN
        CALL err_mgr.raise_error(sqlerrm, sqlerrm, 404, sqlstate);
END;
$$;

ALTER FUNCTION kp_api_ui.crud_supplier() OWNER TO postgres;

REVOKE ALL ON FUNCTION kp_api_ui.crud_supplier() FROM PUBLIC;

CREATE OR REPLACE FUNCTION utl_notify.send_claim2mail(p_claim_id bigint) RETURNS utl_core.call_result
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_result                        utl_core.call_result;
    v_smtp_server                   VARCHAR(256) := kp_core.get_code('mail_server');
    v_smtp_port                     INTEGER      := kp_core.get_code('mail_port')::INTEGER;
    v_smtp_user                     VARCHAR(256) := kp_core.get_code('from_email');
    v_smtp_password                 VARCHAR(256) := kp_core.get_code('from_pass');
    v_claim_id                      BIGINT;
    v_date_begin                    TIMESTAMP;
    v_date_end                      TIMESTAMP;
    v_personal_account              kp_core.claim.personal_account%TYPE;
    v_service_sum                   kp_core.claim.service_sum%TYPE;
    v_email_notice                  kp_core.claim.email_notice%TYPE;
    v_supplier_name                 TEXT;
    v_service_name                  kp_core.supplier_account.service_name%TYPE;
    v_service_code_fmt              TEXT;
    v_attr_name                     kp_core.scenario_attr.attr_name%TYPE;
    v_payment_system_service_code   kp_core.supplier_account.payment_system_service_code%TYPE;
    v_currency                      INTEGER;
    v_supplier_unp                  kp_core.supplier.supplier_unp%TYPE;
    v_email_regexp                  TEXT         := '[A-Za-z0-9._%-]+@[A-Za-z0-9._%-]+\.[A-Za-z]{2,4}';
    c_message_template              TEXT         := '<html>
  <head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
  </head>
  <body>
    <br>{str1}
    <br>{str2}
    <br>{str3}
    <br>{str4}
    <br>{str5}
    <br>{str6}
    <p><img moz-do-not-send="false"
        src="cid:{qrcode}" alt="qrcode" width="125"
        height="125">-- </p>
  </body>
</html>';
    c_str_2                CONSTANT TEXT         := 'Наименование услуги: %s';
    c_str_4                CONSTANT TEXT         := 'Сумма к оплате: %s';
    c_str_5                CONSTANT TEXT         := 'Срок оплаты: %s';
    c_str_6                CONSTANT TEXT         := 'Номер услуги в ЕРИП: %s';
    c_subject              CONSTANT TEXT         := 'Требование на оплату';
    v_message                       TEXT;
    v_qr_code                       bytea;
    v_send_result                   TEXT;
    c_status_invalid_email CONSTANT INTEGER      := -1;
    c_status_send_error    CONSTANT INTEGER      := -2;
    c_status_success       CONSTANT INTEGER      := 3;
BEGIN
    SELECT c.claim_id,
           c.date_begin,
           c.date_end,
           c.personal_account,
           c.service_sum,
           c.email_notice,
           FORMAT('%s УНП (%s)', s.supplier_name, s.supplier_unp)                                    AS supplier_name,
           sa.service_name,
           FORMAT('(%s)', sa.payment_system_service_code)                                               service_code_fmt,
           CASE WHEN saa.supplier_account_id IS NOT NULL THEN saa.attr_name ELSE sattr.attr_name END AS attr_name,
           COALESCE(sa.payment_system_service_code, '')                                              AS payment_system_service_code,
           c.claim_currency::INTEGER                                                                 AS currency,
           COALESCE(s.supplier_unp, '')                                                              AS supplier_unp
    INTO
        v_claim_id,
        v_date_begin,
        v_date_end,
        v_personal_account,
        v_service_sum,
        v_email_notice,
        v_supplier_name,
        v_service_name,
        v_service_code_fmt,
        v_attr_name,
        v_payment_system_service_code,
        v_currency,
        v_supplier_unp
    FROM kp_core.claim c
             JOIN kp_core.supplier_account sa
                  ON sa.supplier_account_id = c.supplier_account_id
             JOIN kp_core.supplier s
                  ON s.supplier_id = sa.supplier_id
             JOIN kp_core.service_scenario ss
                  ON ss.scenario_id = sa.scenario_id
             JOIN kp_core.scenario_attr sattr
                  ON sattr.scenario_id = ss.scenario_id
             LEFT OUTER JOIN kp_core.supplier_account_attr saa
                             ON sa.supplier_account_id = saa.supplier_account_id
                                 AND sattr.scenario_id = saa.scenario_id
                                 AND sattr.attr_code = saa.attr_code
    WHERE c.claim_id = p_claim_id
      AND sattr.attr_code = 745;

    IF v_claim_id IS NOT NULL THEN
        IF NULLIF(v_email_notice, '') IS NOT NULL AND v_email_notice ~ v_email_regexp THEN

            v_message := c_message_template;

            v_message := REPLACE(v_message, '{str1}', v_supplier_name);
            v_message := REPLACE(v_message, '{str2}', FORMAT(c_str_6, v_service_code_fmt));
            v_message := REPLACE(v_message, '{str3}', FORMAT(c_str_2, v_service_name));
            --RAISE NOTICE '%', v_message;
            v_message := REPLACE(v_message, '{str4}', CONCAT(v_attr_name, ' ', v_personal_account));
            v_message := REPLACE(v_message, '{str5}', FORMAT(c_str_4, utl_str.curr2word(v_service_sum, v_currency)));
            v_message := REPLACE(v_message, '{str6}', FORMAT(c_str_5,
                                                             REPLACE(
                                                                     TO_CHAR(v_date_end, 'dd.mm.yyyy hh24:mi:ss'),
                                                                     '00:00:00', '23:59:59')));
            v_message := REPLACE(v_message, '{qrcode}', 'image1');

            v_qr_code := kp_core.get_qrcode(p_service_code => v_payment_system_service_code,
                                            p_personal_account => v_personal_account,
                                            p_currency => v_currency,
                                            p_amount => v_service_sum,
                                            p_unp => v_supplier_unp);
            v_send_result := utl_smtp.send_smtp_mail(smtp_server => v_smtp_server,
                                                     smtp_port => v_smtp_port,
                                                     smtp_user => v_smtp_user,
                                                     smtp_pass => v_smtp_password,
                                                     receiver => v_email_notice,
                                                     cc => NULL::TEXT[],
                                                     topic => c_subject,
                                                     content => v_message,
                                                     mime_type => 'html',
                                                     content_id => '<image1>',
                                                     attach_name => 'qrcode.gif',
                                                     attach_image => TRUE,
                                                     image_type => 'gif',
                                                     image_inline => TRUE,
                                                     attach_body => v_qr_code);
            v_result.success := v_send_result = 'Send';
            IF v_result.success THEN
                v_result.error_code := c_status_success;
            ELSE
                v_result.error_text := utl_nls.get_message_text_fmt('Send email error. %s', v_send_result);
                v_result.error_code := c_status_send_error;
            END IF;
        ELSE
            v_result.success := FALSE;
            v_result.error_text := utl_nls.get_message_text('Email address incorrect');
            v_result.error_code := c_status_invalid_email;
        END IF;
    ELSE
        v_result.success := FALSE;
        v_result.error_text := utl_nls.get_message_text_fmt('Requirement %s was not found.', p_claim_id::TEXT);
        v_result.error_code := 0;
    END IF;

    UPDATE kp_core.claim_to_mail
    SET (send_date, send_result, error_text) = (kp_core.current_server_timestamp(), v_result.error_code,
                                                v_result.error_text)
    WHERE claim_id = p_claim_id;

    IF NOT v_result.success THEN
        PERFORM obj_mgr.audit(22,
                              COALESCE(v_result.error_text, '') ||
                              utl_nls.get_message_text_fmt(
                                      'Information on the submitted claim was not sent to the email address %s',
                                      v_email_notice), 0, FALSE);
    ELSE
        PERFORM obj_mgr.audit(22,
                              COALESCE(v_result.error_text, '') ||
                              utl_nls.get_message_text_fmt(
                                      'Information on the submitted claim has been sent to the email address %s ',
                                      v_email_notice), 0, FALSE);
    END IF;

    RETURN v_result;
END ;
$$;

ALTER FUNCTION utl_notify.send_claim2mail(p_claim_id bigint) OWNER TO postgres;

REVOKE ALL ON FUNCTION utl_notify.send_claim2mail(p_claim_id bigint) FROM PUBLIC;

CREATE OR REPLACE FUNCTION utl_audit.init_rs_op_audit_archive_ui(p_file_path character varying) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_job_id      BIGINT;
    v_job_part_id BIGINT;
    v_param_id    BIGINT;
BEGIN
    SELECT job_id::BIGINT, job_part_id::BIGINT
    INTO v_job_id, v_job_part_id
    FROM kp_core.job_part p
    WHERE LOWER(TRIM(p.imp_dir::TEXT)) = LOWER(TRIM(p_file_path));

    IF v_job_id IS NULL THEN
        v_job_id := 2;
--         v_job_id := NEXTVAL('kp_core.seq_job_config_id');
        INSERT INTO kp_core.job_config (job_id, job_name, start_date, is_once, num, is_minute, is_from_to_time,
                                        min_time_from, min_time_to, is_day, is_everyn_day, is_work_day, is_week,
                                        some_day, last_exec, is_more_one_job_in_queue, is_on, error_msg, process_count,
                                        out_server_id, is_break_job_part, minute_num, is_daymonth, is_last_month_day,
                                        everyn_week, run_mode, error_datetime, error_text)
        VALUES (v_job_id, 'Формирование архива журнала аудита',
                DATE_TRUNC('day', kp_core.current_server_timestamp()) + INTERVAL '1 day 2 hour',
                '0', 1, '0', '0', NULL, NULL, '1', '0', '0',
                '0', NULL, NULL, NULL, '0', '', 2, 911, '1', NULL, '0', '0', NULL, NULL, NULL, NULL);

        --Первая часть - для юай - подготовить один день
        v_job_part_id := NEXTVAL('kp_core.seq_job_part_id');
        INSERT INTO kp_core.job_part (base_id, job_part_id, job_id, order_num, sql, tmp_file_name, id_field_name,
                                      is_for_cur_period, num_of_prev_period, period_type, job_part_name, is_on, exp_dir,
                                      action_type, imp_dir, after_imp_dir, log_file_name, ftp_host, ftp_port,
                                      ftp_username, ftp_password, proxy_type, proxy_host, proxy_port, proxy_username,
                                      proxy_password, is_ftp, is_use_date, copy_exp_dir, run_as, user_name_as,
                                      password_as, last_status, last_exec_date, sum_field_name, ftp_ispassive_mode,
                                      show_filter_for_log, com_file, param_com_file, is_ftp_n, ftp_host_n, ftp_port_n,
                                      ftp_username_n, ftp_password_n, ftp_ispassive_mode_n, proxy_type_n, proxy_host_n,
                                      proxy_username_n, proxy_password_n, message_type_id, max_file_size, use_esign,
                                      export_type, report_id, sid_serial, dir_in_err, proxy_port_n, error_datetime,
                                      error_text)
        VALUES (NULL, v_job_part_id, v_job_id, 42,
                'select p_file_id, p_error_text, p_result from utl_audit.op_audit_archive_day(:p_arm, :p_day)',
                NULL, NULL, '0', NULL, 0, 'Подготовка архива 42', '1', NULL, 5, NULL, NULL,
                NULL, NULL, 0, NULL, NULL, -1, NULL, 0, NULL, NULL, '0', '0', NULL, 0,
                NULL, NULL, NULL, NULL, NULL, '1', '0', NULL, NULL, '0', NULL, 0, NULL, NULL, '1',
                -1, NULL, NULL, NULL, NULL, 0, 0, 2, NULL, NULL, NULL, 0, NULL, NULL);

        v_param_id := NEXTVAL('kp_core.seq_job_part_param_id');
        INSERT INTO kp_core.job_part_param (base_id, job_part_param_id, job_part_id, param_name, param_value,
                                            is_auto_inc,
                                            is_auto_clear_at_new_day, access_type, param_type_id)
        VALUES (NULL, v_param_id, v_job_part_id, 'p_arm', '0', NULL, NULL, 0, 2);

        v_param_id := NEXTVAL('kp_core.seq_job_part_param_id');
        INSERT INTO kp_core.job_part_param (base_id, job_part_param_id, job_part_id, param_name, param_value,
                                            is_auto_inc,
                                            is_auto_clear_at_new_day, access_type, param_type_id)
        VALUES (NULL, v_param_id, v_job_part_id, 'p_day', '10.10.2020', NULL, NULL, 0, 5);

        --Вторая часть - пишем из kp_sms.file_ на диск
        v_job_part_id := NEXTVAL('kp_core.seq_job_part_id');
        INSERT INTO kp_core.job_part (job_part_id, job_id, order_num, sql, tmp_file_name, id_field_name,
                                      is_for_cur_period, num_of_prev_period, period_type, job_part_name, is_on, exp_dir,
                                      action_type, imp_dir, after_imp_dir, log_file_name, ftp_host, ftp_port,
                                      ftp_username, ftp_password, proxy_type, proxy_host, proxy_port, proxy_username,
                                      proxy_password, is_ftp, is_use_date, copy_exp_dir, run_as, user_name_as,
                                      password_as, last_status, last_exec_date, sum_field_name, ftp_ispassive_mode,
                                      show_filter_for_log, com_file, param_com_file, is_ftp_n, ftp_host_n, ftp_port_n,
                                      ftp_username_n, ftp_password_n, ftp_ispassive_mode_n, proxy_type_n, proxy_host_n,
                                      proxy_username_n, proxy_password_n, message_type_id, max_file_size, use_esign,
                                      export_type, report_id, sid_serial, dir_in_err, proxy_port_n, error_datetime,
                                      error_text)
        VALUES (v_job_part_id, v_job_id, 43, 'SELECT t.file_id,
       f.file_name_only file_name,
       f.file_data_raw file_data,
       NULL ftp_login,
       NULL ftp_password,
       (SELECT exp_dir from job_part where job_part_id = :p_job_part_id) ftp_dir_out,
       NULL ftp_server,
       NULL ftp_port,
       abonent,
       NULL ftp_timeout,
       NULL ftp_dir_in,
       NULL ftp_dir_in_bak,
       NULL ftp_dir_in_err,
       (SELECT copy_exp_dir from job_part where job_part_id = :p_job_part_id) ftp_copy_exp_dir,
       ''L'' transport_type
  FROM file_exported t, file_ f
where t.file_id = f.file_id and f.message_type_id = 800', NULL, NULL, '0', NULL, 0, 'Экспорт архива аудита', '1',
                'file://' || p_file_path, 8,
                NULL, '5555', 'file://' || p_file_path || '/exp', NULL, 0, NULL, NULL, -1, NULL, 0, NULL, NULL, '0',
                '0',
                'file://' || p_file_path || '/bkp', 0, NULL, NULL, NULL, NULL, NULL, '1', '0',
                NULL,
                NULL, '0', NULL, 0, NULL, NULL, '1', -1, NULL, NULL, NULL, NULL, 0, 0, 2, NULL, NULL, NULL, 0, NULL,
                NULL);

        --         INSERT INTO kp_sms.job_part(job_part_id, job_id, order_num, sql, period_type, job_part_name, is_on, action_type,
--                                     tmp_file_name, imp_dir, exp_dir, after_imp_dir, log_file_name, copy_exp_dir,
--                                     dir_in_err)
--         VALUES (v_job_part_id, v_job_id, 1,
--                 'select p_result result, p_error_text from utl_msg.stat_archive_create(:p_file_id)',
--                 1, 'SMS', p_enabled::VARCHAR, 3, '*.795', p_file_path, p_file_path || '/exp', p_file_path || '/bkp',
--                 p_file_path || '/imp.log', p_file_path || '/exp/copy', p_file_path || '/err');

        v_param_id := NEXTVAL('kp_core.seq_job_part_param_id');
        INSERT INTO kp_core.job_part_param (job_part_param_id, job_part_id, param_name, param_value, access_type,
                                            param_type_id)
        VALUES (v_param_id, v_job_part_id, 'p_job_part_id', v_job_part_id, 0, 2);

    END IF;

    RETURN v_job_id;
END;
$$;

ALTER FUNCTION utl_audit.init_rs_op_audit_archive_ui(p_file_path character varying) OWNER TO postgres;

REVOKE ALL ON FUNCTION utl_audit.init_rs_op_audit_archive_ui(p_file_path character varying) FROM PUBLIC;

CREATE OR REPLACE FUNCTION utl_audit.init_rs_op_audit_archive(p_file_path character varying, p_days integer) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_job_id      BIGINT;
    v_job_part_id BIGINT;
    v_param_id    BIGINT;
BEGIN
    SELECT job_id::BIGINT, job_part_id::BIGINT
    INTO v_job_id, v_job_part_id
    FROM kp_core.job_part p
    WHERE LOWER(TRIM(p.imp_dir::TEXT)) = LOWER(TRIM(p_file_path));

    IF v_job_id IS NULL THEN
        v_job_id := 1;
--        v_job_id := NEXTVAL('kp_core.seq_job_config_id');
        INSERT INTO kp_core.job_config (job_id, job_name, start_date, is_once, num, is_minute, is_from_to_time,
                                        min_time_from, min_time_to, is_day, is_everyn_day, is_work_day, is_week,
                                        some_day, last_exec, is_more_one_job_in_queue, is_on, error_msg, process_count,
                                        out_server_id, is_break_job_part, minute_num, is_daymonth, is_last_month_day,
                                        everyn_week, run_mode, error_datetime, error_text)
        VALUES (v_job_id, 'Формирование архива журнала аудита',
                DATE_TRUNC('day', kp_core.current_server_timestamp()) + INTERVAL '1 day 2 hour',
                '0', 1, '0', '0', NULL, NULL, '1', '0', '0',
                '0', NULL, NULL, NULL, '1', '', 2, 911, '1', NULL, '0', '0', NULL, NULL, NULL, NULL);

        --Первая часть - пишем файл в kp_sms.file_ и удаляем из kp_sms.sms_statistic
        v_job_part_id := NEXTVAL('kp_core.seq_job_part_id');
        INSERT INTO kp_core.job_part (base_id, job_part_id, job_id, order_num, sql, tmp_file_name, id_field_name,
                                      is_for_cur_period, num_of_prev_period, period_type, job_part_name, is_on, exp_dir,
                                      action_type, imp_dir, after_imp_dir, log_file_name, ftp_host, ftp_port,
                                      ftp_username, ftp_password, proxy_type, proxy_host, proxy_port, proxy_username,
                                      proxy_password, is_ftp, is_use_date, copy_exp_dir, run_as, user_name_as,
                                      password_as, last_status, last_exec_date, sum_field_name, ftp_ispassive_mode,
                                      show_filter_for_log, com_file, param_com_file, is_ftp_n, ftp_host_n, ftp_port_n,
                                      ftp_username_n, ftp_password_n, ftp_ispassive_mode_n, proxy_type_n, proxy_host_n,
                                      proxy_username_n, proxy_password_n, message_type_id, max_file_size, use_esign,
                                      export_type, report_id, sid_serial, dir_in_err, proxy_port_n, error_datetime,
                                      error_text)
        VALUES (NULL, v_job_part_id, v_job_id, 1,
                'select p_file_id, p_error_text, p_result from utl_audit.op_audit_archive(:p_arm, :p_days)',
                NULL, NULL, '0', NULL, 0, 'Подготовка архива', '1', NULL, 5, NULL, NULL,
                NULL, NULL, 0, NULL, NULL, -1, NULL, 0, NULL, NULL, '0', '0', NULL, 0,
                NULL, NULL, NULL, NULL, NULL, '1', '0', NULL, NULL, '0', NULL, 0, NULL, NULL, '1',
                -1, NULL, NULL, NULL, NULL, 0, 0, 2, NULL, NULL, NULL, 0, NULL, NULL);

        v_param_id := NEXTVAL('kp_core.seq_job_part_param_id');
        INSERT INTO kp_core.job_part_param (base_id, job_part_param_id, job_part_id, param_name, param_value,
                                            is_auto_inc,
                                            is_auto_clear_at_new_day, access_type, param_type_id)
        VALUES (NULL, v_param_id, v_job_part_id, 'p_arm', '0', NULL, NULL, 0, 2);

        v_param_id := NEXTVAL('kp_core.seq_job_part_param_id');
        INSERT INTO kp_core.job_part_param (base_id, job_part_param_id, job_part_id, param_name, param_value,
                                            is_auto_inc,
                                            is_auto_clear_at_new_day, access_type, param_type_id)
        VALUES (NULL, v_param_id, v_job_part_id, 'p_days', p_days::TEXT, NULL, NULL, 0, 2);

        --Вторая часть - пишем из kp_sms.file_ на диск
        v_job_part_id := NEXTVAL('kp_core.seq_job_part_id');
        INSERT INTO kp_core.job_part (job_part_id, job_id, order_num, sql, tmp_file_name, id_field_name,
                                      is_for_cur_period, num_of_prev_period, period_type, job_part_name, is_on, exp_dir,
                                      action_type, imp_dir, after_imp_dir, log_file_name, ftp_host, ftp_port,
                                      ftp_username, ftp_password, proxy_type, proxy_host, proxy_port, proxy_username,
                                      proxy_password, is_ftp, is_use_date, copy_exp_dir, run_as, user_name_as,
                                      password_as, last_status, last_exec_date, sum_field_name, ftp_ispassive_mode,
                                      show_filter_for_log, com_file, param_com_file, is_ftp_n, ftp_host_n, ftp_port_n,
                                      ftp_username_n, ftp_password_n, ftp_ispassive_mode_n, proxy_type_n, proxy_host_n,
                                      proxy_username_n, proxy_password_n, message_type_id, max_file_size, use_esign,
                                      export_type, report_id, sid_serial, dir_in_err, proxy_port_n, error_datetime,
                                      error_text)
        VALUES (v_job_part_id, v_job_id, 2, 'SELECT t.file_id,
       f.file_name_only file_name,
       f.file_data_raw file_data,
       NULL ftp_login,
       NULL ftp_password,
       (SELECT exp_dir from job_part where job_part_id = :p_job_part_id) ftp_dir_out,
       NULL ftp_server,
       NULL ftp_port,
       abonent,
       NULL ftp_timeout,
       NULL ftp_dir_in,
       NULL ftp_dir_in_bak,
       NULL ftp_dir_in_err,
       (SELECT copy_exp_dir from job_part where job_part_id = :p_job_part_id) ftp_copy_exp_dir,
       ''L'' transport_type
  FROM file_exported t, file_ f
where t.file_id = f.file_id and f.message_type_id = 800', NULL, NULL, '0', NULL, 0, 'Экспорт архива аудита', '1',
                'file://' || p_file_path, 8,
                NULL, '5555', 'file://' || p_file_path || '/exp', NULL, 0, NULL, NULL, -1, NULL, 0, NULL, NULL, '0',
                '0',
                'file://' || p_file_path || '/bkp', 0, NULL, NULL, NULL, NULL, NULL, '1', '0',
                NULL,
                NULL, '0', NULL, 0, NULL, NULL, '1', -1, NULL, NULL, NULL, NULL, 0, 0, 2, NULL, NULL, NULL, 0, NULL,
                NULL);

        --         INSERT INTO kp_sms.job_part(job_part_id, job_id, order_num, sql, period_type, job_part_name, is_on, action_type,
--                                     tmp_file_name, imp_dir, exp_dir, after_imp_dir, log_file_name, copy_exp_dir,
--                                     dir_in_err)
--         VALUES (v_job_part_id, v_job_id, 1,
--                 'select p_result result, p_error_text from utl_msg.stat_archive_create(:p_file_id)',
--                 1, 'SMS', p_enabled::VARCHAR, 3, '*.795', p_file_path, p_file_path || '/exp', p_file_path || '/bkp',
--                 p_file_path || '/imp.log', p_file_path || '/exp/copy', p_file_path || '/err');

        v_param_id := NEXTVAL('kp_core.seq_job_part_param_id');
        INSERT INTO kp_core.job_part_param (job_part_param_id, job_part_id, param_name, param_value, access_type,
                                            param_type_id)
        VALUES (v_param_id, v_job_part_id, 'p_job_part_id', v_job_part_id, 0, 2);

    END IF;

    RETURN v_job_id;
END;
$$;

ALTER FUNCTION utl_audit.init_rs_op_audit_archive(p_file_path character varying, p_days integer) OWNER TO postgres;

REVOKE ALL ON FUNCTION utl_audit.init_rs_op_audit_archive(p_file_path character varying, p_days integer) FROM PUBLIC;

CREATE OR REPLACE FUNCTION pstp_o_user.execute_incoming_request(p_request_uuid uuid, p_client_ip character varying, p_request jsonb, OUT p_response json, OUT p_error_code integer, OUT p_error_text character varying) RETURNS record
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_protocol_name_request  TEXT    := 'UserRequest';
    v_protocol_name_response TEXT    := 'UserResponse';
    v_protocol_id            INTEGER := 3;
    v_request_name           TEXT    := 'Unknown';
    v_protocol_name          TEXT    := 'Unknown';
    v_request                kp_core.request_ref;
    v_request_path           jsonpath;
    v_request_id             BIGINT;
    v_version                VARCHAR(5);
    v_terminal_id            VARCHAR(16);
    v_token                  TEXT;
    v_lang                   VARCHAR(2);
    v_err_detail             TEXT;
    v_err_hint               TEXT;
    v_err_ctx                TEXT;
    v_err_code               TEXT;
    v_request_payload        jsonb;
    v_response_payload       json;
    v_response_header        json;
    v_record                 RECORD;
    v_result                 utl_core.call_result;
    v_token_info             kp_core.token_session;
    v_user_type_id           BIGINT;
    v_user_supplier_id       BIGINT;
    v_needs_auth             BOOLEAN;
    v_action                 TEXT;
    v_start_time             TIMESTAMP;
BEGIN
    v_request_id := utl_online.get_request_id(TRUE);

    --Protocollllllllllllll
    v_protocol_name := utl_json.get(p_request, '$.keyvalue().key');
    IF v_protocol_name <> v_protocol_name_request THEN
        PERFORM utl_online.log_request(v_request_id, v_protocol_id, v_request_name, p_request::TEXT,
                                       p_request_uuid, p_client_ip);
        CALL err_mgr.raise_error(utl_nls.get_message_text_fmt('Unknown protocol %s.', v_protocol_name),
                                 'e_invalid_protocol', 189);
    END IF;

    --Request
    v_request_path := CONCAT('$.', v_protocol_name_request)::jsonpath;
    v_request_name := utl_json.get(p_request, CONCAT(v_request_path, '.RequestType'));
    v_request_payload := jsonb_path_query(p_request, v_request_path)::jsonb;

    -- DB Table validation
    BEGIN
        SELECT *
        INTO STRICT v_request
        FROM kp_core.request_ref
        WHERE request_name = v_request_name
          AND protocol_id = v_protocol_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            CALL err_mgr.raise_error('Неверное название запроса: ' || v_request_name, 'e_invalid_request', 189);
    END;

    --for logging
    v_start_time := kp_core.current_server_timestamp();

    --Решаем, нужна ли авторизация
    -------!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    v_action := COALESCE(utl_json.get(p_request, v_request_path || '.Action', FALSE), 'LKPU');
    v_needs_auth := CASE WHEN v_request_name = 'Create' AND v_action = 'OWN' THEN FALSE
        WHEN v_request_name = 'ResetPassword' THEN FALSE
        WHEN v_request_name = 'RemindLogin' THEN FALSE
        ELSE TRUE
        END ;
    -----------------------------------------------------------------
    IF v_needs_auth THEN
        --Private mandatories
        v_token := utl_json.get(p_request, v_request_path || '.Token', FALSE);
        v_lang := utl_json.get(p_request, v_request_path || '.Lang', FALSE);
        -------!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        IF v_request_name NOT IN ('Create', 'ResetPassword', 'RemindLogin') THEN
            v_version := utl_json.get(p_request, v_request_path || '.Version');
            v_terminal_id := utl_json.get(p_request, v_request_path || '.TerminalId');
        END IF;
        -----------------------------------------------------------------
        --Token verifying
        FOR v_record IN SELECT * FROM pstp_o_message.token_verify(v_token) LOOP
            v_result := v_record.result;
            IF NOT v_result.success THEN
                IF v_result.error_code = 403 THEN
                    CALL err_mgr.raise_error('The token has expired.', 'e_token_expired', 403);
                ELSE
                    CALL err_mgr.raise_error(v_result.error_text, 'e_token_expired', v_result.error_code);
                END IF;
            END IF;
            v_token_info := v_record.token_info;
        END LOOP;
        --Context populating
        PERFORM kp_context.set_context(v_token_info.user_id, NULL, 'RU');
        SELECT type_id, personal_num
        INTO v_user_type_id, v_user_supplier_id
        FROM kp_core.user_
        WHERE user_id = v_token_info.user_id;

        PERFORM SET_CONFIG('kp_context.user_type_id', v_user_type_id::TEXT, FALSE);
        PERFORM SET_CONFIG('kp_context.user_supplier_id', v_user_supplier_id::TEXT, FALSE);
        PERFORM SET_CONFIG('kp_context.pstpo.token'::TEXT, v_token_info.token, FALSE);
    END IF;
    --Context populating with the arm
    PERFORM SET_CONFIG('kp_context.app_name', 'Кабинет ПУ', FALSE);
    PERFORM SET_CONFIG('kp_context.app_id', '2', FALSE);

    CASE v_request_name
        WHEN 'UserList' THEN v_response_payload := pstp_o_user.user_get_list(v_request_payload);
        WHEN 'Create' THEN v_response_payload := pstp_o_user.user_create(v_request_payload);
        WHEN 'EditUser' THEN v_response_payload := pstp_o_user.user_edit(v_request_payload);
        WHEN 'DeleteUser' THEN v_response_payload := pstp_o_user.user_delete(v_request_payload);
        WHEN 'ResetPassword' THEN v_response_payload := pstp_o_user.password_reset_free(v_request_payload);
        WHEN 'RemindLogin' THEN v_response_payload := pstp_o_user.login_reset_free(v_request_payload);
        ELSE CALL err_mgr.raise_error(utl_nls.get_message_text_fmt('Unknown request type %s.', v_request_name),
                                      'e_invalid_request', 189);
        END CASE;

    p_error_text := NULL::VARCHAR;
    p_error_code := 0;
    v_response_header := JSON_BUILD_OBJECT('Token', v_token, 'ErrorCode', p_error_code);
    p_response := JSON_STRIP_NULLS(JSON_BUILD_OBJECT(v_protocol_name_response,
                                                     utl_json.concat(
                                                             JSON_BUILD_OBJECT('RequestType', v_request_name),
                                                             utl_json.concat(v_response_header, v_response_payload))));

    IF v_request.log_need THEN
        PERFORM utl_online.log_request_all(v_request_id, v_protocol_id, v_request_name, p_request::TEXT,
                                           p_request_uuid, p_client_ip, v_start_time, p_response::TEXT,
                                           p_error_code, p_error_text);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_err_code = RETURNED_SQLSTATE, v_err_hint = PG_EXCEPTION_HINT, v_err_ctx = PG_EXCEPTION_CONTEXT, v_err_detail = PG_EXCEPTION_DETAIL;

        IF v_err_code = 'KPEXC' THEN
            --Пользовательское
            p_error_code := v_err_hint::INTEGER;
            p_error_text := sqlerrm::VARCHAR;
        ELSE
            --Необработанное
            p_error_text := utl_nls.get_message_text(err_mgr.normalize_error(v_err_code, sqlerrm));

            RAISE NOTICE '%', p_error_text;

            p_error_code := 189;
            p_error_text := utl_nls.get_message_text_fmt('%s', p_error_text);
            --             p_error_text :=
--                     utl_nls.get_message_text_fmt('Internal error processing request %s (%s)', v_request_name,
--                                                  p_error_text);
            PERFORM log_mgr.write_error(p_error_text, sqlerrm, v_request_id);
        END IF;

        v_response_header := JSON_BUILD_OBJECT('Token', v_token, 'ErrorCode',
                                               JSON_BUILD_OBJECT('evalue', p_error_code, '@ErrorText', p_error_text));
        p_response :=
                JSON_BUILD_OBJECT(v_protocol_name_response,
                                  utl_json.concat(JSON_BUILD_OBJECT('RequestType', v_request_name),
                                                  v_response_header));

        IF v_request.log_need THEN
            PERFORM utl_online.log_request_all(v_request_id, v_protocol_id, v_request_name, p_request::TEXT,
                                               p_request_uuid, p_client_ip, v_start_time, p_response::TEXT,
                                               p_error_code, p_error_text);
        END IF;
END;
$_$;

ALTER FUNCTION pstp_o_user.execute_incoming_request(p_request_uuid uuid, p_client_ip character varying, p_request jsonb, OUT p_response json, OUT p_error_code integer, OUT p_error_text character varying) OWNER TO postgres;

REVOKE ALL ON FUNCTION pstp_o_user.execute_incoming_request(p_request_uuid uuid, p_client_ip character varying, p_request jsonb, OUT p_response json, OUT p_error_code integer, OUT p_error_text character varying) FROM PUBLIC;

CREATE OR REPLACE FUNCTION pstp_o_user.user_edit(p_request jsonb) RETURNS json
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_user_id              BIGINT;
    v_user_type_id         BIGINT;
    v_user_supplier_id     BIGINT;
    v_edit_user_id         BIGINT;
    v_edit_user_type_id    BIGINT;
    v_edit_login           TEXT;
    v_edit_supplier_id     BIGINT;
    v_need_change_password BOOLEAN;
    v_block                INTEGER;
    v_reset                INTEGER;
    v_old_password         TEXT;
    v_new_password         TEXT;
    v_curr_password        TEXT;
    v_email                TEXT;
    v_phone                TEXT;
    v_name                 TEXT;

BEGIN
    SELECT * INTO v_user_id, v_user_type_id, v_user_supplier_id FROM kp_context.pstpo_get_context();
    v_edit_user_id := utl_json.get(p_request, '$.UserId', FALSE);
    v_edit_login := utl_json.get(p_request, '$.Login.evalue', FALSE);

    SELECT user_id, personal_num::BIGINT, type_id, login
    INTO v_edit_user_id, v_edit_supplier_id, v_edit_user_type_id, v_edit_login
    FROM kp_core.user_
    WHERE user_id = v_edit_user_id
       OR login = v_edit_login
    LIMIT 1;

    IF v_edit_user_id IS NULL THEN
        --Редактируем себя
        v_edit_user_id := v_user_id;
        --Смена пароля
        v_need_change_password := utl_json.get(p_request, '$.NeedChangePassword.evalue', FALSE)::INTEGER = 1;
        IF v_need_change_password THEN
            v_old_password := utl_json.get(p_request, '$.NeedChangePassword.\@OldPassword');
            v_new_password := utl_json.get(p_request, '$.NeedChangePassword.\@NewPassword');
            SELECT password, login INTO v_curr_password, v_edit_login FROM kp_core.user_ WHERE user_id = v_edit_user_id;
            IF UPPER(v_curr_password) <> UPPER(v_old_password) THEN
                CALL err_mgr.raise_error('Old password does not match', 'e_no_data', 404);
            END IF;
            UPDATE kp_core.user_ SET password = v_new_password WHERE user_id = v_edit_user_id;
            PERFORM obj_mgr.audit(8, FORMAT('Пользователь с логином %s сменил свой пароль', v_edit_login));
        END IF;
    ELSE
        --Редактируем другого пользователя
        IF v_edit_login IS NULL THEN
            CALL err_mgr.raise_error('Not found Login or UserId', 'e_no_data', 404);
        END IF;
        --Проверка роли
        IF v_user_type_id != 3 THEN
            CALL err_mgr.raise_error('User is not admin, editing prohibited', 'e_no_data', 404);
        END IF;
        IF v_edit_user_type_id != 4 THEN
            CALL err_mgr.raise_error('User to edit is admin, editing prohibited', 'e_no_data', 404);
        END IF;
        --Проверка поставщика
        IF v_user_supplier_id != v_edit_supplier_id THEN
            CALL err_mgr.raise_error('User is of another supplier, editing prohibited', 'e_no_data', 404);
        END IF;
        --Блокировка/разблокировка
        v_block := utl_json.get(p_request, '$.Blocked', FALSE)::INTEGER;
        IF v_block IN (0, 1) THEN
            UPDATE kp_core.user_ SET blocked = v_block::BOOLEAN WHERE user_id = v_edit_user_id;
        END IF;
        --Сброс пароля
        v_reset := utl_json.get(p_request, '$.ResetPassword', FALSE)::INTEGER;
        IF v_reset = 1 THEN
            PERFORM kp_core.user_reset_password(v_edit_login);
        END IF;
        --Редактирование сущности
        v_email := utl_json.get(p_request, '$.Login.\@EMail', FALSE);
        v_phone := utl_json.get(p_request, '$.Login.\@PhoneNumber', FALSE);
        v_name := utl_json.get(p_request, '$.Login.\@Name', FALSE);
        IF v_name IS NOT NULL THEN
            UPDATE kp_core.user_ SET name = v_name WHERE user_id = v_edit_user_id;
        END IF;
        IF v_phone IS NOT NULL THEN
            UPDATE kp_core.user_ SET phone_number = v_phone WHERE user_id = v_edit_user_id;
        END IF;
        IF v_email IS NOT NULL THEN
            UPDATE kp_core.user_ SET email = v_email WHERE user_id = v_edit_user_id;
        END IF;
    END IF;

    RETURN '{}'::json;
END
$_$;

ALTER FUNCTION pstp_o_user.user_edit(p_request jsonb) OWNER TO postgres;

REVOKE ALL ON FUNCTION pstp_o_user.user_edit(p_request jsonb) FROM PUBLIC;

CREATE OR REPLACE FUNCTION pstp_o_user.password_reset_free(p_request jsonb) RETURNS json
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_login        TEXT;
    v_email        TEXT;
    v_db_user_id BIGINT;
    v_db_email     TEXT;
BEGIN
    v_login := utl_json.get(p_request, '$.Login.evalue', TRUE);
    v_email := utl_json.get(p_request, '$.Login.\@EMail', TRUE);

    SELECT user_id, email
    INTO v_db_user_id, v_db_email
    FROM kp_core.user_
    WHERE LOWER(login) = LOWER(v_login) and lower(email) = lower(v_email)
    LIMIT 1;

    IF v_db_user_id IS NULL THEN
        CALL err_mgr.raise_error('Login not found or email does not fit user login', 'e_no_data', 409);
    END IF;

    --Сброс пароля
    PERFORM kp_core.user_reset_password(v_login);

    RETURN '{}'::json;
END
$_$;

ALTER FUNCTION pstp_o_user.password_reset_free(p_request jsonb) OWNER TO postgres;

REVOKE ALL ON FUNCTION pstp_o_user.password_reset_free(p_request jsonb) FROM PUBLIC;

CREATE OR REPLACE FUNCTION pstp_o_message.token_verify(p_token text, OUT result utl_core.call_result, OUT token_info kp_core.token_session) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user kp_core.user_;
BEGIN
    SELECT t.* INTO token_info FROM kp_core.token_session t WHERE t.token = p_token FOR UPDATE;
    IF token_info.token IS NULL THEN
        result.error_text = utl_nls.get_message_text('The token has expired.');
        result.success := FALSE;
        result.error_code := 403;
    ELSE
        result.success := kp_core.current_server_timestamp() - token_info.token_time < INTERVAL '60 minute';
        IF NOT result.success THEN
            result.error_text := utl_nls.get_message_text('The token has expired.');
            result.error_code := 403;
        ELSE
            SELECT u.* INTO v_user FROM kp_core.user_ u WHERE u.user_id = token_info.user_id;
            IF v_user.user_id IS NULL THEN
                result.error_text := utl_nls.get_message_text('User is not registered.');
                result.error_code := 401;
                result.success := FALSE;
            ELSIF v_user.blocked THEN
                result.error_text := utl_nls.get_message_text('The user is blocked.');
                result.error_code := 408;
                result.success := FALSE;
            END IF;
        END IF;
    END IF;
EXCEPTION
    WHEN SQLSTATE '55P03' THEN
        result.error_text = utl_nls.get_message_text('Another request with this token is already in progress.');
        result.success := FALSE;
        result.sql_error_code := sqlstate;
        result.sql_error_msg := sqlerrm;
        result.error_code := 189;
    WHEN OTHERS THEN
        result.error_text = sqlerrm::VARCHAR;
        result.sql_error_code := sqlstate;
        result.sql_error_msg := sqlerrm;
        result.error_code := 189;
        result.success := FALSE;
END;
$$;

ALTER FUNCTION pstp_o_message.token_verify(p_token text, OUT result utl_core.call_result, OUT token_info kp_core.token_session) OWNER TO postgres;

REVOKE ALL ON FUNCTION pstp_o_message.token_verify(p_token text, OUT result utl_core.call_result, OUT token_info kp_core.token_session) FROM PUBLIC;

CREATE OR REPLACE PROCEDURE obj_mgr.monitor_client()
    LANGUAGE plpgsql
    AS $$
    -- Провека состояния пользователей. Если блокирован по числу не удачных попыток и сброс блокировки.
    -- Если пароль просрочен
DECLARE
    r                          RECORD;
    v_lt                       TIMESTAMP := kp_core.current_server_timestamp();
    v_interval_change_password INTEGER   := 0;
    v_auto_block_time          INTEGER   := 0;
BEGIN
    PERFORM kp_context.set_context(0, '127.0.0.1', 'RU');
    SET APPLICATION_NAME = 'internal job - monitor client';
    SELECT COALESCE((SELECT COALESCE(pp.property_value, pp.value_default)
                     FROM kp_core.password_property pp
                     WHERE pp.property_name = 'interval_change_password')::INTEGER, 0),
           COALESCE((SELECT COALESCE(pp.property_value, pp.value_default)
                     FROM kp_core.password_property pp
                     WHERE pp.property_name = 'auto_block_time')::INTEGER, 0)
    INTO v_interval_change_password, v_auto_block_time;

    FOR r IN SELECT * FROM kp_core.user_ LOOP
        IF v_auto_block_time > 0 AND r.blocked = TRUE AND r.failed_login > 0 AND
           (r.date_blocked + INTERVAL '1 minute' * v_auto_block_time) <= v_lt THEN
            UPDATE kp_core.user_ SET blocked = FALSE, failed_login = 0, date_blocked = NULL WHERE user_id = r.user_id;
        END IF;
        IF v_interval_change_password > 0 AND
           (DATE_TRUNC('day', r.date_change_password) + INTERVAL '1 day' * v_interval_change_password) <
           DATE_TRUNC('day', v_lt) AND r.password_expire = FALSE THEN
            UPDATE kp_core.user_ SET password_expire = TRUE WHERE user_id = r.user_id;
        END IF;
    END LOOP;

END;
$$;

ALTER PROCEDURE obj_mgr.monitor_client() OWNER TO postgres;

CREATE OR REPLACE PROCEDURE obj_mgr.audit_client_action()
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_session_info pg_stat_activity%ROWTYPE;
    v_user_id      NUMERIC(19);
    v_lang         VARCHAR(2);
    v_ip_address   VARCHAR(256);
    v_user         kp_core.user_%ROWTYPE;
BEGIN
    SELECT * INTO v_session_info FROM pg_stat_activity WHERE pid = PG_BACKEND_PID();
    SELECT t.user_id::NUMERIC, t.ip_address, t.lang
    INTO v_user_id, v_ip_address, v_lang
    FROM kp_context.get_context() t;
    IF (v_session_info.backend_type = 'client backend')
        AND (COALESCE(v_ip_address, v_session_info.client_addr::VARCHAR) IS NOT NULL)
        AND (v_user_id IS NOT NULL) THEN
        SELECT c.* INTO v_user FROM kp_core.user_ c WHERE c.user_id = v_user_id;
        IF v_user.blocked = TRUE THEN
            RAISE EXCEPTION 'Пользователь % заблокирован', v_user.login;
        END IF;
    END IF;
END;
$$;

ALTER PROCEDURE obj_mgr.audit_client_action() OWNER TO postgres;

CREATE OR REPLACE FUNCTION kp_core.user_create(client_name character varying, client_login character varying, client_password character varying, client_phone_number character varying, client_type_id bigint, client_supplier_id bigint, client_blocked boolean, client_email character varying, current_login character varying, p_role_id bigint, p_creation_method_id integer) RETURNS numeric
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_can_create    BOOLEAN;
    v_client_id     NUMERIC(19);
    v_client_exists BOOLEAN;
    v_user_id       BIGINT;
    v_lang          VARCHAR(2);
    v_ip_address    VARCHAR(256);
    v_pass          VARCHAR(10);
    v_error_text    TEXT;
    v_op_audit_id   BIGINT;
BEGIN
    IF instr(client_login, ' ') > 0 THEN
        RAISE EXCEPTION 'The use of a space is not allowed in the login';
    END IF;

    -- Проверить на право добавлять пользователя
    SELECT TRUE
    INTO v_can_create
    FROM kp_core.user_type t,
         kp_core.user_ u
    WHERE t.type_id > u.type_id
      AND u.user_id = CURRENT_SETTING('kp_context.user_id', TRUE)::BIGINT
      AND t.type_id = client_type_id;

    IF NOT COALESCE(v_can_create, FALSE) THEN
        -- Нет права на создание такого пользовотеля
        v_op_audit_id := obj_mgr.audit(7, 'You cannot create a new user', 1);
        CALL err_mgr.raise_error('You cannot create a new user', 'e_no_privilege',
                                 404);
    END IF;

    -- Проверить что новый пользоваель отсутствует
    SELECT TRUE INTO v_client_exists FROM kp_core.user_ u WHERE LOWER(u.login) = LOWER(client_login);
    IF COALESCE(v_client_exists, FALSE) THEN
        v_op_audit_id := obj_mgr.audit(7, 'User exists', 1);
        CALL err_mgr.raise_error('Such a user already exists', 'e_user_exists', 404);
    END IF;
    SELECT t.user_id::BIGINT, t.ip_address, t.lang
    INTO v_user_id, v_ip_address, v_lang
    FROM kp_context.get_context() t;

    -- Генерация пароля
    v_pass := kp_core.gen_password();

    -- Вставка в таблицу пользователей
    v_client_id := NEXTVAL('kp_core.seq_user_id')::NUMERIC(19);
    INSERT INTO kp_core.user_(user_id, name, role_id, login, password, personal_num, type_id,
                              phone_number, email, blocked, db_role, creation_method_id)
    VALUES (v_client_id, client_name, p_role_id, client_login, crypto_mgr.sha256(v_pass)::VARCHAR,
            TO_CHAR(client_supplier_id), client_type_id, client_phone_number, client_email,
            client_blocked, 'web_user', p_creation_method_id);

    PERFORM obj_mgr.audit(7, FORMAT('Создан пользователь с логином %s и ФИО %s', client_login, client_name));

    -- Отправить пароль на почту
    BEGIN
        PERFORM utl_notify.send_password_to_email(TRUE, client_type_id::INTEGER, client_email, client_login, v_pass);
        CALL obj_mgr.audit_action(7, v_client_id::VARCHAR, NULL::xml, NULL::xml, 'user_', 0, NULL::BIGINT,
                                  'Сообщение о регистрации отправлено пользователю на адрес электронной почты ' ||
                                  client_email);
    EXCEPTION
        WHEN OTHERS THEN
            v_error_text := FORMAT('Error: %s', sqlerrm);
            CALL obj_mgr.audit_action(7, v_client_id::VARCHAR, NULL::xml, NULL::xml, 'user_', 1, NULL::BIGINT,
                                      v_error_text);
    END;

    RETURN v_client_id;
END;
$$;

ALTER FUNCTION kp_core.user_create(client_name character varying, client_login character varying, client_password character varying, client_phone_number character varying, client_type_id bigint, client_supplier_id bigint, client_blocked boolean, client_email character varying, current_login character varying, p_role_id bigint, p_creation_method_id integer) OWNER TO postgres;

REVOKE ALL ON FUNCTION kp_core.user_create(client_name character varying, client_login character varying, client_password character varying, client_phone_number character varying, client_type_id bigint, client_supplier_id bigint, client_blocked boolean, client_email character varying, current_login character varying, p_role_id bigint, p_creation_method_id integer) FROM PUBLIC;

CREATE OR REPLACE FUNCTION kp_core.check_user(p_login text, p_ip_address text) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_user kp_core.user_%ROWTYPE;
BEGIN
    SELECT t.*
    INTO v_user
    FROM kp_core.user_ t
    WHERE t.login = p_login;
    IF v_user.user_id IS NULL THEN
        RAISE EXCEPTION 'invalid user';
    END IF;

    IF v_user.blocked = TRUE THEN
        RAISE EXCEPTION 'user blocked';
    END IF;

    IF v_user.ip_address IS NOT NULL AND p_ip_address <> v_user.ip_address THEN
        RAISE EXCEPTION 'invalid ip address %', p_ip_address;
    END IF;
    RETURN v_user.user_id::BIGINT;
END;
$$;

ALTER FUNCTION kp_core.check_user(p_login text, p_ip_address text) OWNER TO postgres;

REVOKE ALL ON FUNCTION kp_core.check_user(p_login text, p_ip_address text) FROM PUBLIC;

CREATE OR REPLACE FUNCTION kp_core.user_reset_password(p_login text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id  NUMERIC(19);
    v_email    TEXT;
    v_new_pass TEXT := kp_core.gen_password();
BEGIN
    SELECT user_id, email INTO v_user_id, v_email FROM kp_core.user_ WHERE LOWER(login) = LOWER(p_login);
    UPDATE kp_core.user_ SET password = crypto_mgr.sha256(v_new_pass) WHERE user_id = v_user_id;
    perform obj_mgr.audit(13, format('Пользователю %s был сброшен пароль', p_login));
    BEGIN
        PERFORM utl_notify.send_password_to_email(FALSE, 1, v_email, p_login, v_new_pass);
        CALL obj_mgr.audit_action(13, v_user_id::VARCHAR, NULL::xml, NULL::xml, 'user_', 0, NULL::BIGINT,
                                  'Сообщение о регистрации отправлено пользователю на адрес электронной почты ' ||
                                  v_email);
    EXCEPTION
        WHEN OTHERS THEN
            CALL obj_mgr.audit_action(11, v_user_id::VARCHAR, NULL::xml, NULL::xml, 'user_', 1, NULL::BIGINT,
                                      sqlerrm);
    END;
    RETURN TRUE;
END;
$$;

ALTER FUNCTION kp_core.user_reset_password(p_login text) OWNER TO postgres;

REVOKE ALL ON FUNCTION kp_core.user_reset_password(p_login text) FROM PUBLIC;

CREATE VIEW kp_api_ui.user_type AS
	SELECT t.type_id,
    t.type_name,
    t.type_description
   FROM (( SELECT u_1.user_id,
            u_1.name,
            u_1.login,
            u_1.password,
            u_1.personal_num,
            u_1.ip_address,
            u_1.blocked,
            u_1.date_blocked,
            u_1.date_add,
            u_1.type_id,
            u_1.phone_number,
            u_1.failed_login,
            u_1.email,
            u_1.password_expire,
            u_1.date_change_password,
            u_1.note,
            u_1.db_role,
            u_1.role_id,
            u_1.creation_method_id
           FROM kp_core.user_ u_1
          WHERE (lower((u_1.login)::text) = lower(((current_setting('request.jwt.claims'::text, true))::json ->> 'app_user'::text)))) u
     JOIN kp_core.user_type t ON ((t.type_id > u.type_id)));

ALTER VIEW kp_api_ui.user_type OWNER TO postgres;

GRANT ALL ON TABLE kp_api_ui.user_type TO web_user;

-- DEPCY: This VIEW is a dependency of TRIGGER: kp_api_ui.user_.crud_user_

CREATE VIEW kp_api_ui.user_ AS
	SELECT t.user_id,
    t.name,
    t.login,
    COALESCE(t.blocked, false) AS blocked,
    t.date_add,
    t.type_id,
    t.phone_number,
    t.email,
        CASE COALESCE(t.blocked, false)
            WHEN false THEN 'Разблокирован'::text
            WHEN true THEN 'Заблокирован'::text
            ELSE NULL::text
        END AS blocked_name,
        CASE COALESCE(t.password_expire, false)
            WHEN false THEN 'Нет'::text
            WHEN true THEN 'Да'::text
            ELSE NULL::text
        END AS password_expire_name,
    ct.type_name,
    t.personal_num AS supplier_id,
    t.date_blocked,
    s.supplier_unp,
    s.supplier_name,
    t.role_id,
    r.name AS role_name,
    ct.type_description
   FROM (((kp_core.user_ t
     JOIN kp_core.user_type ct ON ((t.type_id = ct.type_id)))
     LEFT JOIN kp_core.supplier s ON (((s.supplier_id)::text = (t.personal_num)::text)))
     LEFT JOIN kp_core.user_role r ON ((r.role_id = t.role_id)));

ALTER VIEW kp_api_ui.user_ OWNER TO postgres;

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE kp_api_ui.user_ TO anon_user;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE kp_api_ui.user_ TO web_user;

-- DEPCY: This FUNCTION is a dependency of TRIGGER: kp_api_ui.user_.crud_user_

CREATE OR REPLACE FUNCTION kp_api_ui.crud_user_() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    PERFORM kp_api_ui.ui_dml_before();

    IF (tg_op = 'INSERT') THEN
        SELECT kp_core.user_create(new.name, new.login, NULL, new.phone_number,
                                   new.type_id, new.supplier_id::BIGINT, new.blocked, new.email, NULL, 2, 1)
        INTO new.user_id;
    ELSIF (tg_op = 'UPDATE') THEN
        UPDATE kp_core.user_
        SET name         = new.name,
            login        = new.login,
            personal_num = new.supplier_id,
            blocked      = new.blocked,
            date_blocked = new.date_blocked,
            date_add     = new.date_add::TIMESTAMP,
            type_id      = new.type_id,
            phone_number = new.phone_number,
            email        = new.email,
            role_id      = COALESCE(new.role_id, kp_core.get_field_def('user_', 'role_id')::BIGINT)
        WHERE user_id = old.user_id;
        IF NOT old.blocked AND new.blocked THEN
            PERFORM obj_mgr.audit(9, 'Пользователь ' || new.name || ' заблокирован');
        END IF;
        IF old.blocked AND NOT new.blocked THEN
            PERFORM obj_mgr.audit(10, 'Пользователь ' || new.name || ' разблокирован');
        END IF;
    ELSIF (tg_op = 'DELETE') THEN
        DELETE FROM kp_core.user_ WHERE user_id = old.user_id;
    END IF;

    IF tg_op IN ('INSERT', 'UPDATE') THEN
        SELECT blocked_name INTO new.blocked_name FROM kp_api_ui.user_ WHERE user_id = new.user_id;
    END IF;

    RETURN CASE tg_op WHEN 'DELETE' THEN old ELSE new END;
END
$$;

ALTER FUNCTION kp_api_ui.crud_user_() OWNER TO postgres;

REVOKE ALL ON FUNCTION kp_api_ui.crud_user_() FROM PUBLIC;

CREATE TRIGGER crud_user_
	INSTEAD OF INSERT OR UPDATE OR DELETE ON kp_api_ui.user_
	FOR EACH ROW
	EXECUTE PROCEDURE kp_api_ui.crud_user_();

CREATE OR REPLACE FUNCTION kp_api_ui.server_message_create(p_date_create timestamp without time zone, p_date_send timestamp without time zone, p_heading text, p_message text, p_suppliers bigint[], p_sending_immediately boolean) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_msg_rec    RECORD;
    v_message_id BIGINT;
BEGIN
    INSERT INTO kp_core.supplier_server_message(message_date, note, status, heading, sending_date, sending_immediately)
    VALUES (p_date_create, p_message, case when p_date_send is null then 0 else 1 end, p_heading, p_date_send, p_sending_immediately)
    RETURNING message_id INTO v_message_id;

    FOR v_msg_rec IN SELECT *
                     FROM unnest(p_suppliers) s
                              JOIN kp_core.user_ u ON u.personal_num = s::text
        LOOP
            INSERT INTO kp_core.user_server_message (user_id, message_id, status, supplier_id)
            VALUES (v_msg_rec.user_id, v_message_id, 1, v_msg_rec.s::bigint);
        END LOOP;
    PERFORM obj_mgr.audit(25);
    return v_message_id;
END;
$$;

ALTER FUNCTION kp_api_ui.server_message_create(p_date_create timestamp without time zone, p_date_send timestamp without time zone, p_heading text, p_message text, p_suppliers bigint[], p_sending_immediately boolean) OWNER TO postgres;

REVOKE ALL ON FUNCTION kp_api_ui.server_message_create(p_date_create timestamp without time zone, p_date_send timestamp without time zone, p_heading text, p_message text, p_suppliers bigint[], p_sending_immediately boolean) FROM PUBLIC;

CREATE OR REPLACE FUNCTION kp_api_ui.server_message_update(p_message_id bigint, p_date_send timestamp without time zone, p_heading text, p_message text, p_suppliers bigint[], p_sending_immediately boolean) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_msg_rec  RECORD;
    v_state_id INTEGER;
BEGIN

    SELECT state_id
    INTO v_state_id
    FROM kp_api_ui.supplier_server_message
    WHERE message_id = p_message_id;
    IF v_state_id = 3 THEN
        RAISE 'e_server_message_sent_deletion_prohibited';
    END IF;

    UPDATE kp_core.supplier_server_message
    SET (note, status, heading, sending_date, sending_immediately)
            = (p_message, CASE WHEN p_date_send IS NULL THEN 0 ELSE 1 END, p_heading, p_date_send,
               p_sending_immediately)
    WHERE message_id = p_message_id;

    DELETE FROM kp_core.user_server_message WHERE message_id = p_message_id;
    FOR v_msg_rec IN SELECT *
                     FROM UNNEST(p_suppliers) s
                              JOIN kp_core.user_ u ON u.personal_num = s::TEXT
        LOOP
            INSERT INTO kp_core.user_server_message (user_id, message_id, status, supplier_id)
            VALUES (v_msg_rec.user_id, p_message_id, 1, v_msg_rec.s::BIGINT);
        END LOOP;
    PERFORM obj_mgr.audit(27);
    RETURN p_message_id;
END;
$$;

ALTER FUNCTION kp_api_ui.server_message_update(p_message_id bigint, p_date_send timestamp without time zone, p_heading text, p_message text, p_suppliers bigint[], p_sending_immediately boolean) OWNER TO postgres;

REVOKE ALL ON FUNCTION kp_api_ui.server_message_update(p_message_id bigint, p_date_send timestamp without time zone, p_heading text, p_message text, p_suppliers bigint[], p_sending_immediately boolean) FROM PUBLIC;
