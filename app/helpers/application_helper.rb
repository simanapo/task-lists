module ApplicationHelper
  # TimeWithZoneオブジェクトを指定の日時フォーマットに変換
  # @param [Object] datetime 日時オブジェクト(TimeWithZone)
  # @param [Symbol] type フォーマット
  # @return [String] フォーマット後の文字列
  def formated_datetime(datetime, type = :short)
    datetime.strftime I18n.t("datetime.formats.#{type}") if datetime.present?
  end

  # TimeWithZoneオブジェクトを指定の日付フォーマットに変換
  # @param [Object] datetime 日時オブジェクト(TimeWithZone)
  # @param [Symbol] type フォーマット
  # @return [String] フォーマット後の文字列
  def formated_date(datetime, type = :default)
    datetime.strftime I18n.t("date.formats.#{type}") if datetime.present?
  end

  # TimeWithZoneオブジェクトを指定の時間フォーマットに変換
  # @param [Object] datetime 日時オブジェクト(TimeWithZone)
  # @param [Symbol] type フォーマット
  # @return [String] フォーマット後の文字列
  def formated_time(datetime, type = :default)
    datetime.strftime I18n.t("timefield.formats.#{type}") if datetime.present?
  end

  # TimeWithZoneオブジェクトを指定の曜日フォーマットに変換
  # @param [Object] datetime 日時オブジェクト(TimeWithZone)
  # @param [Symbol] type フォーマット
  # @return [String] 日本の曜日
  def formated_date_week(datetime, type = :abbr_day_names)
    datetime.strftime I18n.t("date.#{type}")[datetime.wday] if datetime.present?
  end
end
