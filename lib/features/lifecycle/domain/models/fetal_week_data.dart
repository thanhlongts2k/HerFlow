// lib/features/lifecycle/domain/models/fetal_week_data.dart
import 'package:flutter/foundation.dart';

/// Dữ liệu phát triển thai nhi theo từng tuần thai (1 - 40)
@immutable
class FetalWeekData {
  /// Tuần thai (1 -> 40)
  final int week;

  /// Tên loại quả/hạt so sánh tương đương kích thước bé
  final String fruitName;

  /// Emoji đại diện cho quả/hạt
  final String fruitEmoji;

  /// Chiều dài ước tính của thai nhi (cm)
  final double approxLengthCm;

  /// Cân nặng ước tính của thai nhi (gram)
  final double approxWeightG;

  /// Điểm nhấn phát triển nổi bật của bé trong tuần
  final String babyHighlights;

  /// Lời khuyên chăm sóc sức khỏe và dinh dưỡng cho mẹ
  final String momTip;

  const FetalWeekData({
    required this.week,
    required this.fruitName,
    required this.fruitEmoji,
    required this.approxLengthCm,
    required this.approxWeightG,
    required this.babyHighlights,
    required this.momTip,
  });

  /// Chuỗi hiển thị kích thước tiện dụng
  String get formattedLength =>
      approxLengthCm > 0 ? '~${approxLengthCm.toStringAsFixed(1)} cm' : '< 0.1 cm';

  /// Chuỗi hiển thị cân nặng tiện dụng
  String get formattedWeight {
    if (approxWeightG >= 1000) {
      return '~${(approxWeightG / 1000).toStringAsFixed(2)} kg';
    } else if (approxWeightG > 0) {
      return '~${approxWeightG.toStringAsFixed(1)} g';
    } else {
      return '< 0.1 g';
    }
  }

  /// Lấy thông tin thai nhi theo tuần thai (tự động clamp trong khoảng 1..40)
  static FetalWeekData getWeekData(int week) {
    final clampedWeek = week.clamp(1, 40);
    return fetalWeeklyDataList[clampedWeek - 1];
  }

  /// Toàn bộ danh mục 40 tuần thai kỳ chuẩn y tế quốc tế
  static const List<FetalWeekData> fetalWeeklyDataList = [
    // ─── TAM CÁ NGUYỆT 1 (TUẦN 1 - 13) ──────────────────────────────────
    FetalWeekData(
      week: 1,
      fruitName: 'Hạt mầm yêu thương',
      fruitEmoji: '🌱',
      approxLengthCm: 0.0,
      approxWeightG: 0.0,
      babyHighlights:
          'Kỳ kinh nguyệt bắt đầu. Cơ thể mẹ đang chuẩn bị lớp niêm mạc tử cung mới và thanh lọc để sẵn sàng đón nhận sự sống.',
      momTip:
          'Bổ sung Acid Folic (400 mcg/ngày) ngay từ giai đoạn này để ngăn ngừa dị tật ống thần kinh sớm.',
    ),
    FetalWeekData(
      week: 2,
      fruitName: 'Trứng vàng thụ tinh',
      fruitEmoji: '🥚',
      approxLengthCm: 0.0,
      approxWeightG: 0.0,
      babyHighlights:
          'Sự rụng trứng và thụ tinh kỳ diệu diễn ra tại ống dẫn trứng. Hợp tử mang trọn bộ mã di truyền của cả bố và mẹ.',
      momTip:
          'Giữ tinh thần vui vẻ, thư thái, ngủ đủ giấc và tuyệt đối tránh xa rượu bia, thuốc lá.',
    ),
    FetalWeekData(
      week: 3,
      fruitName: 'Phôi nang tí hon',
      fruitEmoji: '🪺',
      approxLengthCm: 0.01,
      approxWeightG: 0.001,
      babyHighlights:
          'Hợp tử phân chia nhanh chóng thành phôi nang hàng trăm tế bào và nhẹ nhàng làm tổ sâu trong niêm mạc tử cung.',
      momTip:
          'Uống nhiều nước ấm, ăn thực phẩm thanh đạm giàu kẽm và protein dễ tiêu hóa.',
    ),
    FetalWeekData(
      week: 4,
      fruitName: 'Hạt mè nhỏ',
      fruitEmoji: '🌰',
      approxLengthCm: 0.1,
      approxWeightG: 0.05,
      babyHighlights:
          'Phôi thai hình thành 3 lá phôi (ngoại bì, trung bì, nội bì) — nền tảng tạo nên mọi cơ quan nội tạng của con.',
      momTip:
          'Dùng que thử thai để kiểm tra vạch kết quả hoặc xét nghiệm máu Beta-hCG để đón nhận tin vui.',
    ),
    FetalWeekData(
      week: 5,
      fruitName: 'Hạt cam nhỏ',
      fruitEmoji: '🍊',
      approxLengthCm: 0.2,
      approxWeightG: 0.1,
      babyHighlights:
          'Ống thần kinh của bé bắt đầu khép lại. Ống tim nguyên thủy đập những nhịp rung động đầu tiên trong đời.',
      momTip:
          'Chia nhỏ 5-6 bữa ăn trong ngày nếu bắt đầu có cảm giác buồn nôn, ốm nghén hoặc mệt mỏi.',
    ),
    FetalWeekData(
      week: 6,
      fruitName: 'Hạt đậu lăng',
      fruitEmoji: '🫘',
      approxLengthCm: 0.4,
      approxWeightG: 0.2,
      babyHighlights:
          'Mầm mắt, tai và các chồi tay chân bé nhỏ bắt đầu nhú ra. Nhịp tim thai đã có thể quan sát trên siêu âm đầu dò.',
      momTip:
          'Tránh các mùi thức ăn nồng cay, giữ gừng tươi hoặc kẹo ngậm bạc hà để xoa dịu dạ dày.',
    ),
    FetalWeekData(
      week: 7,
      fruitName: 'Quả việt quất',
      fruitEmoji: '🫐',
      approxLengthCm: 1.0,
      approxWeightG: 0.5,
      babyHighlights:
          'Não bộ phân hóa 2 bán cầu với tốc độ phát triển hàng trăm nghìn tế bào thần kinh mỗi phút. Bàn tay hình thành dạng mái chèo.',
      momTip:
          'Uống đủ 2-2.5 lít nước mỗi ngày và tranh thủ chợp mắt ngắn 15-20 phút vào buổi trưa.',
    ),
    FetalWeekData(
      week: 8,
      fruitName: 'Quả mâm xôi',
      fruitEmoji: '🍓',
      approxLengthCm: 1.6,
      approxWeightG: 1.0,
      babyHighlights:
          'Mí mắt che chở đôi mắt nhỏ, ngón tay và ngón chân bắt đầu tách biệt rõ ràng. Bé có những cử động uốn mình nhẹ nhàng.',
      momTip:
          'Đi khám thai lần đầu tiên để xác nhận thai trong tử cung và đo chiều dài đầu mông (CRL).',
    ),
    FetalWeekData(
      week: 9,
      fruitName: 'Quả nho xanh',
      fruitEmoji: '🍇',
      approxLengthCm: 2.3,
      approxWeightG: 2.0,
      babyHighlights:
          'Tim thai hoàn thiện 4 buồng tim đập rộn ràng (140-170 nhịp/phút). Cổ tay, mắt cá chân và cơ bắp bắt đầu cử động.',
      momTip:
          'Chọn áo ngực chất liệu cotton mềm mại, không gọng để nâng đỡ ngực đang tăng kích thước.',
    ),
    FetalWeekData(
      week: 10,
      fruitName: 'Quả quất vàng',
      fruitEmoji: '🍊',
      approxLengthCm: 3.1,
      approxWeightG: 4.0,
      babyHighlights:
          'Kết thúc giai đoạn phôi thai, bé chính thức trở thành "thai nhi". Thận bắt đầu sản xuất và bài tiết nước ối.',
      momTip:
          'Bổ sung canxi và vitamin D qua sữa tươi tiệt trùng, sữa chua và tắm nắng sớm nhẹ.',
    ),
    FetalWeekData(
      week: 11,
      fruitName: 'Quả sung ngọt',
      fruitEmoji: '🍈',
      approxLengthCm: 4.1,
      approxWeightG: 7.0,
      babyHighlights:
          'Xương sống dần cứng cáp, mầm răng sữa ẩn dưới nướu, bé bắt đầu có phản xạ nuốt và ngáp nhỏ.',
      momTip:
          'Chuẩn bị lịch làm xét nghiệm sàng lọc trước sinh (NIPT hoặc Double Test) từ tuần 11 đến 13.',
    ),
    FetalWeekData(
      week: 12,
      fruitName: 'Quả chanh ta',
      fruitEmoji: '🍋',
      approxLengthCm: 5.4,
      approxWeightG: 14.0,
      babyHighlights:
          'Các phản xạ tự nhiên xuất hiện: bé biết cuộn ngón chân, nắm hờ bàn tay và cử động cơ mặt.',
      momTip:
          'Mốc vàng siêu âm đo độ mờ da gáy (NT) tầm soát hội chứng Down trong tuần này mẹ không nên bỏ lỡ!',
    ),
    FetalWeekData(
      week: 13,
      fruitName: 'Quả đậu Hà Lan',
      fruitEmoji: '🫛',
      approxLengthCm: 7.4,
      approxWeightG: 23.0,
      babyHighlights:
          'Dấu vân tay độc nhất vô nhị của bé đã hình thành. Dây thanh âm đang hoàn thiện.',
      momTip:
          'Chúc mừng mẹ đã vượt qua Tam cá nguyệt thứ nhất! Nguy cơ sảy thai giảm mạnh, mẹ sắp bước vào giai đoạn khỏe khoắn nhất.',
    ),

    // ─── TAM CÁ NGUYỆT 2 (TUẦN 14 - 27) ──────────────────────────────────
    FetalWeekData(
      week: 14,
      fruitName: 'Quả chanh vàng',
      fruitEmoji: '🍋',
      approxLengthCm: 8.7,
      approxWeightG: 43.0,
      babyHighlights:
          'Bé mọc lớp lông tơ mịn (lanugo) giúp giữ ấm. Cổ dài ra và đầu cử động linh hoạt hơn.',
      momTip:
          'Cơn nghén giảm dần, mẹ có thể bắt đầu đi bộ nhẹ nhàng 20-30 phút mỗi ngày để tăng tuần hoàn máu.',
    ),
    FetalWeekData(
      week: 15,
      fruitName: 'Quả táo nhỏ',
      fruitEmoji: '🍎',
      approxLengthCm: 10.1,
      approxWeightG: 70.0,
      babyHighlights:
          'Khung xương tiếp tục tích tụ canxi để cứng cáp. Bé nhạy cảm với ánh sáng rọi qua thành bụng mẹ.',
      momTip:
          'Tập thói quen nằm ngủ nghiêng sang trái với gối ôm để máu lưu thông về nhau thai tốt nhất.',
    ),
    FetalWeekData(
      week: 16,
      fruitName: 'Quả bơ sáp',
      fruitEmoji: '🥑',
      approxLengthCm: 11.6,
      approxWeightG: 100.0,
      babyHighlights:
          'Bé chạm mốc 100g! Đôi mắt có thể đảo nhẹ, cơ bắp cứng cáp giúp con giữ thẳng lưng hơn.',
      momTip:
          'Bắt đầu thoa dầu dưỡng hoặc kem chống rạn da dịu nhẹ lên bụng, đùi và ngực mỗi tối.',
    ),
    FetalWeekData(
      week: 17,
      fruitName: 'Củ cải đỏ',
      fruitEmoji: '🧅',
      approxLengthCm: 13.0,
      approxWeightG: 140.0,
      babyHighlights:
          'Lớp mỡ nâu dưới da bắt đầu tích lũy giúp điều hòa thân nhiệt. Dây rốn phát triển dày và chắc khỏe hơn.',
      momTip:
          'Đổi tư thế từ từ khi ngồi dậy hoặc đứng lên để tránh hoa mắt do hạ huyết áp tư thế.',
    ),
    FetalWeekData(
      week: 18,
      fruitName: 'Quả ớt chuông',
      fruitEmoji: '🫑',
      approxLengthCm: 14.2,
      approxWeightG: 190.0,
      babyHighlights:
          'Ống tai phát triển hoàn chỉnh. Bé đã lắng nghe được tiếng tim đập, tiếng ruột réo và giọng nói ấm áp của mẹ!',
      momTip:
          'Hãy bắt đầu trò chuyện và cho bé nghe nhạc giao hưởng hoặc âm thanh thiên nhiên êm dịu.',
    ),
    FetalWeekData(
      week: 19,
      fruitName: 'Quả cà chua lớn',
      fruitEmoji: '🍅',
      approxLengthCm: 15.3,
      approxWeightG: 240.0,
      babyHighlights:
          'Lớp chất gây (vernix caseosa) màu trắng bao bọc bảo vệ làn da non nớt của bé trong môi trường nước ối.',
      momTip:
          'Nhiều mẹ bắt đầu cảm nhận cú "máy thai" đầu tiên — như chú cá nhỏ quẫy đuôi nhẹ nhàng trong bụng.',
    ),
    FetalWeekData(
      week: 20,
      fruitName: 'Quả chuối tiêu',
      fruitEmoji: '🍌',
      approxLengthCm: 25.6,
      approxWeightG: 300.0,
      babyHighlights:
          'Đã hoàn thành một nửa chặng đường! Bé nuốt nước ối đều đặn, rèn luyện hệ tiêu hóa hoạt động.',
      momTip:
          'Thời điểm vàng để siêu âm 4D/5D hình thái học (tuần 20-22) khảo sát chi tiết cấu trúc cơ quan nội tạng của con.',
    ),
    FetalWeekData(
      week: 21,
      fruitName: 'Củ cà rốt',
      fruitEmoji: '🥕',
      approxLengthCm: 26.7,
      approxWeightG: 360.0,
      babyHighlights:
          'Bé biết mút ngón tay cái, những cú đạp và xoay mình trở nên mạnh mẽ, rõ ràng hơn.',
      momTip:
          'Ăn nhiều rau củ có màu sắc phong phú, uống nhiều nước để tránh chứng táo bón thai kỳ.',
    ),
    FetalWeekData(
      week: 22,
      fruitName: 'Quả đu đủ nhỏ',
      fruitEmoji: '🥭',
      approxLengthCm: 27.8,
      approxWeightG: 430.0,
      babyHighlights:
          'Lông mày và mí mắt đã hiện rõ. Vị giác của con nhận biết được mùi vị nước ối thay đổi theo món mẹ ăn.',
      momTip:
          'Kiểm tra nồng độ sắt và hemoglobin trong máu để kịp thời bổ sung viên sắt nếu có dấu hiệu thiếu máu.',
    ),
    FetalWeekData(
      week: 23,
      fruitName: 'Quả xoài lớn',
      fruitEmoji: '🥭',
      approxLengthCm: 28.9,
      approxWeightG: 500.0,
      babyHighlights:
          'Bé cán mốc nửa cân (500g)! Phổi bắt đầu sản sinh surfactant giúp phế nang không bị xẹp khi hít thở.',
      momTip:
          'Kê chân cao bằng gối mềm khi ngồi hoặc nằm nghỉ để giảm hiện tượng sưng phù bàn chân.',
    ),
    FetalWeekData(
      week: 24,
      fruitName: 'Bắp ngô ngọt',
      fruitEmoji: '🌽',
      approxLengthCm: 30.0,
      approxWeightG: 600.0,
      babyHighlights:
          'Bé phản ứng giật mình với âm thanh lớn bất ngờ. Chu kỳ ngủ - thức của con bắt đầu rõ nét.',
      momTip:
          'Thực hiện nghiệm pháp dung nạp đường huyết (OGTT) trong khoảng tuần 24-28 để tầm soát tiểu đường thai kỳ.',
    ),
    FetalWeekData(
      week: 25,
      fruitName: 'Củ cải xoăn',
      fruitEmoji: '🥬',
      approxLengthCm: 34.6,
      approxWeightG: 660.0,
      babyHighlights:
          'Tóc con bắt đầu mọc, các mạch máu ở phổi phát triển mạnh mẽ. Bé thích thú xoay người theo tư thế của mẹ.',
      momTip:
          'Duy trì uống đủ canxi theo chỉ dẫn bác sĩ để tránh hiện tượng chuột rút cơ bắp bắp chân ban đêm.',
    ),
    FetalWeekData(
      week: 26,
      fruitName: 'Cây xà lách',
      fruitEmoji: '🥬',
      approxLengthCm: 35.6,
      approxWeightG: 760.0,
      babyHighlights:
          'Đôi mắt bé lần đầu tiên hé mở sau nhiều tháng nhắm nghiền. Con có thể chớp mắt khi thấy luồng sáng mạnh.',
      momTip:
          'Thực hiện theo dõi và đếm cử động thai (thai máy) vào các khung giờ cố định trong ngày.',
    ),
    FetalWeekData(
      week: 27,
      fruitName: 'Bông cải xanh',
      fruitEmoji: '🥦',
      approxLengthCm: 36.6,
      approxWeightG: 875.0,
      babyHighlights:
          'Các nếp gấp vỏ não gia tăng gấp bội. Bé tập hít thở nhịp nhàng bằng nước ối và có thể nấc cụt nhẹ.',
      momTip:
          'Tuần kết thúc Tam cá nguyệt thứ hai! Mẹ hãy chuẩn bị tinh thần và sức khỏe bước vào chặng về đích.',
    ),

    // ─── TAM CÁ NGUYỆT 3 (TUẦN 28 - 40) ──────────────────────────────────
    FetalWeekData(
      week: 28,
      fruitName: 'Quả cà tím lớn',
      fruitEmoji: '🍆',
      approxLengthCm: 37.6,
      approxWeightG: 1000.0,
      babyHighlights:
          'Chạm mốc 1 Kilogram kỳ diệu! Mắt con có thể nhìn thấy ánh sáng mờ mờ, hàng mi cong dần hoàn thiện.',
      momTip:
          'Tần suất khám thai tăng lên 2 tuần/lần. Tiêm vắc xin uốn ván mũi 1 nếu mẹ mang thai lần đầu.',
    ),
    FetalWeekData(
      week: 29,
      fruitName: 'Quả bí ngô hồ lô',
      fruitEmoji: '🎃',
      approxLengthCm: 38.6,
      approxWeightG: 1150.0,
      babyHighlights:
          'Xương toàn thân tiếp tục khoáng hóa cứng cáp nhờ lượng canxi mẹ cung cấp mỗi ngày.',
      momTip:
          'Tránh nằm ngửa vì tử cung nặng có thể chèn ép tĩnh mạch chủ dưới, gây tụt huyết áp và mệt mỏi.',
    ),
    FetalWeekData(
      week: 30,
      fruitName: 'Bắp cải tròn',
      fruitEmoji: '🥬',
      approxLengthCm: 39.9,
      approxWeightG: 1320.0,
      babyHighlights:
          'Lượng nước ối đạt mức tối đa, sau đó sẽ giảm dần để nhường chỗ cho cơ thể bé lớn nhanh.',
      momTip:
          'Bắt đầu lên danh sách đồ sơ sinh cho bé và đồ đi sinh cho mẹ vào một chiếc giỏ sẵn sàng.',
    ),
    FetalWeekData(
      week: 31,
      fruitName: 'Quả dừa xiêm',
      fruitEmoji: '🥥',
      approxLengthCm: 41.1,
      approxWeightG: 1500.0,
      babyHighlights:
          'Bé có thể quay đầu từ trái sang phải, phản xạ nắm tay rất chặt chẽ và cảm nhận hương vị rõ rệt.',
      momTip:
          'Chú ý các cơn gò sinh lý Braxton Hicks (gò giả không đau). Khi thấy gò, mẹ hãy ngồi nghỉ và uống nước ấm.',
    ),
    FetalWeekData(
      week: 32,
      fruitName: 'Củ đậu lớn',
      fruitEmoji: '🍠',
      approxLengthCm: 42.4,
      approxWeightG: 1700.0,
      babyHighlights:
          'Móng tay móng chân đã mọc chạm đầu ngón. Lớp mỡ dưới da làm mờ dần các nếp nhăn nheo trên cơ thể con.',
      momTip:
          'Tiêm vắc xin uốn ván mũi 2 (cách mũi 1 ít nhất 1 tháng và trước ngày dự sinh tối thiểu 1 tháng).',
    ),
    FetalWeekData(
      week: 33,
      fruitName: 'Quả dứa thơm',
      fruitEmoji: '🍍',
      approxLengthCm: 43.7,
      approxWeightG: 1900.0,
      babyHighlights:
          'Hộp sọ của bé vẫn giữ tính mềm dẻo, các mảnh xương chưa hàn gắn để dễ dàng uốn nắn khi qua ống sinh.',
      momTip:
          'Tập các bài tập thở thiền và bài tập sàn chậu (Kegel) hỗ trợ quá trình rặn sinh nở thuận lợi.',
    ),
    FetalWeekData(
      week: 34,
      fruitName: 'Quả dưa lưới',
      fruitEmoji: '🍈',
      approxLengthCm: 45.0,
      approxWeightG: 2150.0,
      babyHighlights:
          'Hệ miễn dịch của con được củng cố mạnh mẽ nhờ tiếp nhận nguồn kháng thể quý giá truyền từ mẹ qua nhau thai.',
      momTip:
          'Tìm hiểu và ghi nhớ các dấu hiệu chuyển dạ thực sự: ra nhớt hồng, rỉ ối, hoặc cơn co thắt bụng đều đặn.',
    ),
    FetalWeekData(
      week: 35,
      fruitName: 'Quả bí đao',
      fruitEmoji: '🥒',
      approxLengthCm: 46.2,
      approxWeightG: 2400.0,
      babyHighlights:
          'Hầu hết các bé đã quay đầu xuống dưới (ngôi đầu thuận lợi). Không gian tử cung trở nên chật chội hơn với con.',
      momTip:
          'Chuẩn bị sẵn hồ sơ khám thai, thẻ bảo hiểm y tế và căn cước công dân trong giỏ đồ sinh.',
    ),
    FetalWeekData(
      week: 36,
      fruitName: 'Quả đu đủ chín',
      fruitEmoji: '🥭',
      approxLengthCm: 47.4,
      approxWeightG: 2600.0,
      babyHighlights:
          'Lớp lông tơ rụng dần. Bé tăng cân nhanh chóng khoảng 200 - 250 gram mỗi tuần trong giai đoạn này.',
      momTip:
          'Bắt đầu khám thai đều đặn mỗi tuần 1 lần, thực hiện đo biểu đồ tim thai và cơn gò (Non-stress test - NST).',
    ),
    FetalWeekData(
      week: 37,
      fruitName: 'Củ cải trắng lớn',
      fruitEmoji: '🥕',
      approxLengthCm: 48.6,
      approxWeightG: 2850.0,
      babyHighlights:
          'Bé đạt mốc "Đủ tháng sớm" (Early Term)! Phổi con đã có thể tự thở ổn định nếu chào đời trong tuần này.',
      momTip:
          'Giặt sạch sẽ và phơi khô toàn bộ quần áo, tã lót, chăn sơ sinh bằng nước giặt chuyên dụng cho em bé.',
    ),
    FetalWeekData(
      week: 38,
      fruitName: 'Cây tỏi tây lớn',
      fruitEmoji: '🧅',
      approxLengthCm: 49.8,
      approxWeightG: 3100.0,
      babyHighlights:
          'Phản xạ bú và nuốt hoàn toàn thuần thục. Dây rốn dài khoảng 50cm đưa dưỡng chất nuôi con.',
      momTip:
          'Nghỉ ngơi tối đa, không đi du lịch hoặc di chuyển xa khỏi bệnh viện nơi mẹ dự định sinh nở.',
    ),
    FetalWeekData(
      week: 39,
      fruitName: 'Quả dưa hấu nhỏ',
      fruitEmoji: '🍉',
      approxLengthCm: 50.7,
      approxWeightG: 3300.0,
      babyHighlights:
          'Thai nhi đạt mốc "Đủ tháng toàn diện" (Full Term). Não và phổi con tiếp tục hoàn thiện những khâu cuối cùng.',
      momTip:
          'Luôn sạc đầy pin điện thoại, giữ tinh thần lạc quan và liên hệ người thân ngay khi có dấu hiệu chuyển dạ.',
    ),
    FetalWeekData(
      week: 40,
      fruitName: 'Quả dưa hấu tròn lớn',
      fruitEmoji: '🍉',
      approxLengthCm: 51.2,
      approxWeightG: 3500.0,
      babyHighlights:
          'Ngày dự sinh kỳ diệu đã đến! Con đã sẵn sàng 100% để cất tiếng khóc chào thế giới trong vòng tay bố mẹ.',
      momTip:
          'Mọi sự chờ đợi đều xứng đáng! Mẹ hãy vững tâm, tự tin vì mẹ đã làm rất tuyệt vời suốt 40 tuần qua.',
    ),
  ];
}
