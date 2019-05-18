class TasksController

  update_path = ''

  # 子会社取得
  search_subsidiary_company_url = ''
  # CSVファイルアップロードURL
  csv_url = ''
  # タイムアウト
  time_out = ''

  # 左ナビをアクティブにする
  nav_active: ->
    $('#nav-place > a').addClass('menu_active')
    return

  index: ->
    self = this
    # エラー表示
    show_error_message = (element, error_messages) ->
      element.addClass 'error_block'
      element.find('p').remove()

      for error_message in error_messages
        element.append '<p>' + error_message.message + '</p>'
      return
    # 使用地登録 確認
    $('[data-method="confirm"]')
      .on 'ajax:success', (event, data, status, xhr)->
        data = $.parseJSON(xhr.responseText)
        $('[data-remodal-id="modal01"]').remodal().open()
        return
      .on 'ajax:error', (event, xhr, status, error)->
        data = $.parseJSON(xhr.responseText)
        element = $('[data-method="regist_error_message"]')
        show_error_message element, data.errors
        return

    # 使用地登録 登録
    $('[data-method="create"]')
      .on 'ajax:success', (event, data, status, xhr)->
        data = $.parseJSON(xhr.responseText)
        $('[data-remodal-id="modal02"]').remodal().open()
        return
      .on 'ajax:error', (event, xhr, status, error)->
        Application.show_error_modal(xhr)
        return

    # 使用地更新 確認
    $('[data-method="update_confirm"]')
      .on 'ajax:success', (event, data, status, xhr)->
        data = $.parseJSON(xhr.responseText)
        modal = $('[data-remodal-id="edit03-1"]')
        modal.remodal().open()
        modal.find('form').attr('action', self.update_path + '/' + data.id)
        return
      .on 'ajax:error', (event, xhr, status, error)->
        data = $.parseJSON(xhr.responseText)
        element = $(@).find('[data-method="update_error_message"]')
        show_error_message element, data.errors
        return

    # 使用地更新 登録
    $('[data-method="update"]')
      .on 'ajax:success', (event, data, status, xhr)->
        data = $.parseJSON(xhr.responseText)
        $('[data-remodal-id="edit03-3"]').remodal().open()
        return
      .on 'ajax:error', (event, xhr, status, error)->
        Application.show_error_modal(xhr)
        return

    # 使用地削除 確認
    $('[data-method="delete_confirm"]')
      .click ->
        modal = $('[data-remodal-id="delete03-1"]')
        path = self.update_path + '/' + $(@).attr('delete_id')
        updated_at = 'input[name="updated_at"]'
        modal.find('form').attr('action', path)
        modal.find('form').find(updated_at).val($(@).attr('updated_at'))
        modal.remodal().open()
        return

    # 使用地 削除　登録
    $('[data-method="delete"]')
      .on 'ajax:success', (event, data, status, xhr)->
        data = $.parseJSON(xhr.responseText)
        $('[data-remodal-id="delete03-2"]').remodal().open()
        return
      .on 'ajax:error', (event, xhr, status, error)->
        Application.show_error_modal(xhr)
        return


    # 登録完了モーダルを閉じる
    $('[data-method="register_complete"]')
      .click ->
        $('[data-remodal-id="modal02"]').remodal().close()
        Turbolinks.visit(location.toString())
        return

    # 更新完了モーダルを閉じる
    $('[data-method="update_complete"]')
      .click ->
        $('[data-remodal-id="modal02"]').remodal().close()
        Turbolinks.visit(location.toString())
        return

    # 削除完了モーダルを閉じる
    $('[data-method="delete_complete"]')
      .click ->
        $('[data-remodal-id="delete03-2"]').remodal().close()
        Turbolinks.visit(location.toString())
        return


    #########################################################################################################
    # CSVファイル選択時処理
    #########################################################################################################
    selected_csv_file = (self, files) ->
      # 選択されていない
      return if files.length == 0

      formData = new FormData()
      formData.append 'file', files[0]

      $('#csv_name').text(files[0].name)

      # ファイルアップロード非同期通信
      $.ajax
        async: true
        processData: false
        contentType: false
        url: self.csv_url
        type : 'POST'
        data: formData
        timeout: self.time_out
        beforeSend: ->
          $('.error_xs').html('<p style="color: black">ファイルロード中です、しばらくお待ちください</p>')
          $('#upload_button').attr('disabled', true)
      .done (data, textStatus, jqXHR) ->
        $('#csv_file_path').val(data['file_path'])
        $('#csv_character_code').val(data['character_code'])
        $('.error_xs').html('')
        return
      .fail (jqXHR, textStatus, errorThrown) ->
        # エラー表示
        $('.error_xs').html('')
        for k, v of $.parseJSON(jqXHR.responseText)
          $('.error_xs').append('<p>' + v + '</p>')
        return
      .always ->
        $('#upload_button').attr('disabled', false)
      return

    #########################################################################################################
    # CSVアップロード成功結果モーダル
    #########################################################################################################
    set_csv_success_result_modal = (result) ->
      $('[data-remodal-id="upload02"]').find('.modal_text').find('.select').text('登録データ総数 ' + result.process_count + ' 件')
      $('#csv_success_close_button').on 'click', ->
        if result.subsidiary_company_id == undefined
          location.href = location.href.replace( /[\?#].*|$/, ("?company_id=" + result.company_id) )
        else
          location.href = location.href.replace( /[\?#].*|$/, ("?company_id=" + result.company_id + "&subsidiary_company_id=" + result.subsidiary_company_id) )

      return

    #########################################################################################################
    # アップロードモーダル表示
    #########################################################################################################
    open_uplaod_modal = ->
      $('#csv_name').text('選択されていません')
      $('#csv_file_path').val('')
      $('#csv_character_code').val('')
      $('.error_xs').find('p').remove()
      $('input[type="file"]').val('')
      $('[data-remodal-id="upload01"]').remodal().open()
      $('#upload_button').attr('disabled', false)
      return

    #########################################################################################################
    # ファイルアップロード
    #########################################################################################################
    $('#upload_modal_form')
      .on 'ajax:beforeSend', ->
        $('#upload_button').attr('disabled', true)
      .on 'complete', ->
        $('#upload_button').attr('disabled', false)
      .on 'ajax:success', (event, data, status, xhr)->
        $('[data-remodal-id="upload01"]').remodal().close()
        $('[data-remodal-id="upload02"]').remodal().open()
        result = $.parseJSON(xhr.responseText)
        set_csv_success_result_modal result
        return
      .on 'ajax:error', (event, xhr, status, error)->
        if error == "Internal Server Error"
          $('.error_xs').html('')
          for k, v of $.parseJSON(xhr.responseText)
            $('.error_xs').append('<p>' + v + '</p>')
          $('#upload_button').attr('disabled', false)
          return

        $modal = $('[data-remodal-id="upload03"]')
        $modal.find('.failure-number').find('p').remove()
        try
          result = $.parseJSON(xhr.responseText)
          $modal.find('.failure-number').append $('<p>').text("#{result.total_count} 件")
          $modal.find('.failure-number').append $('<p>').append($('<span>').text("#{result.errors.length} 件"))
        catch
          result = { errors: [Application.error_messages.internal_server_error] }
          $modal.find('.failure-number').append $('<p>').text('- 件')
          $modal.find('.failure-number').append $('<p>').append($('<span>').text('- 件'))

        $modal.find('.title_text').html('一括登録に失敗しました。')
        $modal.find('.error-list-wrap').find('p').remove()
        $modal.find('.error-detail-title').show()
        $modal.find('.error-list-wrap').show()
        for error_message in result.errors
          $modal.find('.error-list-wrap').append $('<p>').text("#{error_message}")

        $('[data-remodal-id="upload01"]')
        .one 'closed', ->
          $('[data-remodal-id="upload03"]').remodal().open()
        .remodal()
        .close()

    #########################################################################################################
    # 一括登録ボタン押下時処理
    #########################################################################################################
    $('#upload_modal_open_button').on 'click', ->
      open_uplaod_modal()
      return

    #########################################################################################################
    # 再アップロードボタン押下時
    #########################################################################################################
    $('#reupload_modal_open_button').on 'click', ->
      open_uplaod_modal()
      return

    #########################################################################################################
    # キャンセルボタン押下時
    #########################################################################################################
    $('#upload_cancel').on 'click', ->
      $('[data-remodal-id="upload03"]').remodal().close()
      return

    #########################################################################################################
    # CSVファイル選択時
    #########################################################################################################
    $('#file_csv').on 'change', ->
      selected_csv_file self, this.files
      return

    #########################################################################################################
    # 企業選択プルダウン
    #########################################################################################################

    Application.admin_company_pulldown(self.search_subsidiary_company_url, [-1])

    $('.btn_clear').on 'click', ->
      location.href = location.href.replace( /[\?#].*|$/, "" )

    return

this.Application.tasks = new TasksController
