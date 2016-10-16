class TestPagesController < ApplicationController
  def do_post
    params.permit!
    p = params[:payment]
    js = {
      org_id: p[:org_id],
      trans_type: p[:trans_type],
      order_time: Time.now.strftime("%Y%m%d%H%M%S"),
      order_id: "TST" + Time.now.to_i.to_s,
      pay_pass: "1",
      amount: p[:amount],
      fee: p[:fee],
      order_title: p[:order_title],
      notify_url: AppConfig.get('kaifu.api.notify_url') + "_test_notify",
      callback_url: AppConfig.get('kaifu.api.notify_url') + "_test_callback",
      remote_ip: request.remote_ip
    }
    if p[:trans_type] == 'P001' || p[:trans_type] == 'P003'
      js[:card_no] = '6225886556455713'
      js[:card_holder_name] = '梁益华'
      js[:person_id_num] = '450303197005030016'
    end

    client = Client.find_by(org_id: p[:org_id])
    if client
      biz = Biz::PubEncrypt.new
      js[:mac] = biz.md5_mac(js, client.tmk)
      url = AppConfig.get('pooul.api.pay_url')
      if body_txt = Biz::WebBiz.post_data(url, js.to_json, nil)
        begin
          @js = JSON.parse(body_txt)
          @js.symbolize_keys!
        rescue => e
          @js = {error: e.message}
        end
      else
        @js = {error: 'post_data失败'}
      end
    else
      @js = {error: "org:[#{p[:org_id]}] not found!\n"}
    end
  end

  def gen_qrcode
    qr = RQRCode::QRCode.new("#{root_url}/test_pages/pay")
    qr.as_png.save("public/qrcodes/p001.png")
    qr = RQRCode::QRCode.new("#{root_url}/test_pages/pay_t1")
    qr.as_png.save("public/qrcodes/p002.png")
    qr = RQRCode::QRCode.new("#{root_url}/test_pages/pay_app_t0")
    qr.as_png.save("public/qrcodes/p003.png")
    qr = RQRCode::QRCode.new("#{root_url}/test_pages/pay_app_t1")
    qr.as_png.save("public/qrcodes/p004.png")
    qr = RQRCode::QRCode.new("#{root_url}/test_pages/pay_wap")
    qr.as_png.save("public/qrcodes/p005.png")
    render plain: 'gen_qrcode ok'
  end
end
