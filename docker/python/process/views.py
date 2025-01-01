from django.http import HttpResponse, HttpResponseBadRequest
from django.views.decorators.csrf import csrf_exempt
from PIL import Image
import io


def processed_with_sepia(image_file):
    # セピア色にする加工
    RGBImage = Image.open(image_file).convert("RGB")

    width, height = RGBImage.size
    sepia_image = Image.new("RGB", (width, height))

    for y in range(height):
        for x in range(width):
            r,g,b = RGBImage.getpixel((x, y))
            # セピア調の色合いに変化
            new_r = int(r * 0.393 + g * 0.769 + b * 0.189)
            new_g = int(r * 0.349 + g * 0.686 + b * 0.168)
            new_b = int(r * 0.272 + g * 0.534 + b * 0.131)
            # RGB値が255を超えないように調整
            new_r = min(new_r, 255)
            new_g = min(new_g, 255)
            new_b = min(new_b, 255)
            sepia_image.putpixel((x,y), (new_r, new_g, new_b))
        
    return sepia_image    

@csrf_exempt
def CameraRequest(request):
    if request.method == 'POST' and request.FILES.get('photo'):
        image_file = request.FILES.get('photo')
        if image_file:

            # デバッグ情報を表示するためにprint文を追加
            print('デバッグのコード:受け取った画像のファイル名 = ', image_file.name)
            # 画像を受け取って処理するコードを追加します
            processed_image = processed_with_sepia(image_file)
            

            with io.BytesIO() as output:
                processed_image.save(output,format='PNG')
                processed_image_binary = output.getvalue()

            # レスポンスとして処理済みの画像を返します
            response = HttpResponse(processed_image_binary, content_type = "image/png")

            response['Content-Disposition'] = 'attachment; filename="photo.png"'


            return response
        
    return HttpResponseBadRequest()
        


