class HomeController < ApplicationController
  respond_to :html, :js
  def index
  end
  def kaifu_signin
    js = {
      sendTime: "#{Time.now.strftime("%Y%m%d%H%M%S")}",
      sendSeqId: "SIGNIN#{Time.now.to_i.to_s}",
      transType: "A001"
    }
    if params[:id] == 'd0'
      js[:organizationId] = AppConfig.get('kaifu.user.d0.org_id')
    else
      js[:organizationId] = AppConfig.get('kaifu.user.t1.org_id')
    end

    url = 'http://61.135.202.242:8020/payform/organization'
    uri = URI(url)
    res = Net::HTTP.post_form(uri, data: js.to_json)
    if res.is_a?(Net::HTTPOK)
      @result = res.body.to_s
      begin
        r_js = JSON.parse(@result)
        r = KaifuSignin.new(Biz::KaifuApi.js_to_app_format(js))
        r.update(Biz::KaifuApi.js_to_app_format(r_js))
        r.save
        case r.organization_id
        when AppConfig.get('kaifu.user.d0.org_id')
          key = Biz::KaifuApi.decrypt_signin_key(r.terminal_info, AppConfig.get('kaifu.user.d0.tmk'))
          AppConfig.set('kaifu.user.d0.skey', key)
        when AppConfig.get('kaifu.user.t1.org_id')
          key = Biz::KaifuApi.decrypt_signin_key(r.terminal_info, AppConfig.get('kaifu.user.t1.tmk'))
          AppConfig.set('kaifu.user.t1.skey', key)
        end
        @result = "[签到成功]\n\nkey=#{key}\n\n#{@result.force_encoding('UTF-8')}"
      rescue => e
        @result = "[签到失败] #{e.message}\n\n" + @result.force_encoding('UTF-8')
      end
    end
  end

end
