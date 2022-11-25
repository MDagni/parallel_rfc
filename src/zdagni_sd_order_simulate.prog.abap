************************************************************************
* Developer        : Mehmet Dağnilak
* Description      : Paralel RFC yöntemiyle sipariş simülasyonu örneği
************************************************************************
* History
*----------------------------------------------------------------------*
* User-ID     Date      Description
*----------------------------------------------------------------------*
* MDAGNILAK   20221125  Program created
* <userid>    yyyymmdd  <short description of the change>
************************************************************************

report zdagni_sd_order_simulate.

parameters: p_orders type i default 40,
            p_items  type i default 20,
            p_disabl as checkbox.

start-of-selection.

  perform main.

*&---------------------------------------------------------------------*
*&      Form  main
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
form main.

  data: lt_orders type zdagni_sd_order_simulate_tab,
        ls_order  type zdagni_sd_order_simulate,
        ls_item   type bapiitemin,
        lv_start  type timestampl,
        lv_end    type timestampl.

  ls_order = value #(
                      orderkey = '1'
                      order_header_in = value #(
                                                doc_type   = 'YONS'
                                                sales_org  = 'RL'
                                                distr_chan = 'BY'
                                                division   = 'LA'
                                                qt_valid_f = sy-datum
                                                qt_valid_t = sy-datum
                                                pmnttrms   = 'SKKT'
                                                currency   = 'TRY'
                                               )
                      order_partners = value #(
                                                ( partn_role = 'AG' partn_numb = '0018006006' )
                                                ( partn_role = 'WE' partn_numb = '0018006006' )
                                              )
                    ).

  ls_item = value #(
                    itm_number = 0
                    material   = ''
                    req_qty    = 5000
                    cond_type  = 'IEKI'
                    cond_value = 5
                   ).

  select a882~matnr into table @data(lt_matnr)
         from a882
         join mara
           on mara~matnr eq a882~matnr
          and mara~mstav eq ''
         join mvke
           on mvke~matnr eq a882~matnr
          and mvke~vkorg eq a882~vkorg
          and mvke~vtweg eq a882~vtweg
          and mvke~vmsta eq ''
         where a882~kappl eq 'V'
           and a882~kschl eq 'FYAT'
           and a882~vkorg eq 'RL'
           and a882~vtweg eq 'BY'
           and a882~zterm eq 'SKKT'
           and a882~datbi ge @sy-datum
           and a882~datab le @sy-datum.

  do p_items times.
    ls_item-itm_number = sy-index * 100.
    ls_item-material   = lt_matnr[ ( sy-index - 1 ) mod lines( lt_matnr ) + 1 ].
    append ls_item to ls_order-order_items_in.
  enddo.

  do p_orders times.
    ls_order-orderkey = conv numc5( sy-index ).
    insert ls_order into table lt_orders.
  enddo.

  try.
      lt_orders[ 2 ]-order_header_in-pmnttrms = 'S004'.
      lt_orders[ 3 ]-order_header_in-pmnttrms = 'XXXX'.
    catch cx_sy_itab_line_not_found.
  endtry.

*--------------------------------------------------------------------*
  get time stamp field lv_start.

  call function 'ZDAGNI_SD_ORDER_SIMULATE'
    exporting
      disable_credit_check = abap_true
      disable_parallel     = p_disabl
    changing
      orders               = lt_orders.

  get time stamp field lv_end.
*--------------------------------------------------------------------*

  data(lv_time) = cl_abap_tstmp=>subtract( tstmp1 = lv_end
                                           tstmp2 = lv_start ).

  write:/ lv_time.

  "İşlenemeyen var mı kontrol et. Normalde olmaması gerekir.
  loop at lt_orders assigning field-symbol(<ls_order>) where processed = abap_false.
    write:/ <ls_order>-orderkey, 'işlenememiş!!!'.
  endloop.

endform.          " main
