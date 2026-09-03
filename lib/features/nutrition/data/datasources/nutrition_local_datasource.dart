// lib/features/nutrition/data/datasources/nutrition_local_datasource.dart
import '../../../../core/constants/cycle_phase.dart';
import '../../domain/entities/nutrition_recommendation.dart';

/// Nguồn dữ liệu dinh dưỡng đồng bộ chu kỳ (Cycle-Synced Food Database)
class NutritionLocalDataSource {
  static const Map<CyclePhase, NutritionRecommendation> _recommendations = {
    // 1. PHA HÀNH KINH (MENSTRUAL)
    CyclePhase.menstrual: NutritionRecommendation(
      phase: CyclePhase.menstrual,
      title: 'Hồi Phục & Bổ Máu Ấm Bụng',
      description:
          'Hormone đang ở mức thấp nhất, cơ thể cần năng lượng ấm, giàu chất sắt và dễ tiêu hóa để xoa dịu các cơn co thắt tử cung.',
      superfoods: [
        'Thịt bò thăn nạc',
        'Cải bó xôi (Rau bina)',
        'Cá hồi giàu Omega-3',
        'Hạt bí ngô & hạt lanh',
        'Canh rong biển đậu hũ',
        'Quả mọng (Việt quất, dâu tây)',
      ],
      foodsToAvoid: [
        'Nước đá lạnh & kem',
        'Đồ uống có cồn & rượu bia',
        'Cà phê đậm đặc (gây co thắt cơ)',
        'Thức ăn quá mặn (gây tích nước)',
      ],
      keyNutrients: ['Sắt (Fe)', 'Omega-3', 'Vitamin C', 'Kẽm (Zn)'],
      teaSuggestion: 'Trà gừng ấm pha mật ong hoặc trà quế ấm',
      sampleMeal: 'Cháo sườn bắp bò ấm nóng ăn kèm rau cải bó xôi xào tỏi.',
    ),

    // 2. PHA NANG TRỨNG (FOLLICULAR)
    CyclePhase.follicular: NutritionRecommendation(
      phase: CyclePhase.follicular,
      title: 'Tươi Mát, Trẻ Hóa & Kích Hoạt Năng Lượng',
      description:
          'Estrogen bắt đầu tăng trưởng. Cơ thể sẵn sàng tiếp nhận các món tươi mới, giàu probiotic và hỗ trợ gan chuyển hóa estrogen lành mạnh.',
      superfoods: [
        'Bông cải xanh & súp lơ',
        'Kim chi, sữa chua Hy Lạp',
        'Bơ sáp & dầu ô liu',
        'Trứng gà luộc lòng đào',
        'Yến mạch nguyên cám',
        'Hạt chia & hạnh nhân',
      ],
      foodsToAvoid: [
        'Đồ ăn nhanh chiên ngập dầu',
        'Bánh ngọt chứa đường tinh luyện cao',
        'Thực phẩm chế biến sẵn đóng hộp',
      ],
      keyNutrients: ['Vitamin E', 'Vitamin B-Complex', 'Probiotics', 'Protein sạch'],
      teaSuggestion: 'Trà xanh Matcha hoặc trà hoa cúc tươi mát',
      sampleMeal: 'Salad bơ cá ngừ kèm trứng gà luộc và hạt hạnh nhân lát.',
    ),

    // 3. PHA RỤNG TRỨNG (OVULATION)
    CyclePhase.ovulation: NutritionRecommendation(
      phase: CyclePhase.ovulation,
      title: 'Thải Độc, Chống Viêm & Tăng Sức Bền',
      description:
          'Estrogen đạt đỉnh điểm. Nên ăn nhẹ nhàng, giàu chất chống oxy hóa và chất xơ để gan đào thải lượng estrogen dư thừa một cách mượt mà.',
      superfoods: [
        'Quả mâm xôi & dâu tây',
        'Măng tây & ớt chuông đỏ',
        'Hạt dẻ cười & hạt óc chó',
        'Tôm & hải sản giàu kẽm',
        'Rau xà lách Romaine xoăn',
        'Dưa hấu & nước dừa xiêm',
      ],
      foodsToAvoid: [
        'Thức ăn cay nóng cấp độ cao',
        'Đồ uống có ga nhiều đường',
        'Thịt mỡ béo ngậy',
      ],
      keyNutrients: ['Glutathione', 'Chất xơ hòa tan', 'Axit Folic', 'Vitamin C'],
      teaSuggestion: 'Trà bạc hà tươi hoặc nước dừa tươi nguyên chất',
      sampleMeal: 'Tôm hấp nước dừa ăn kèm măng tây áp chảo tỏi ô-liu.',
    ),

    // 4. PHA HOÀNG THỂ (LUTEAL)
    CyclePhase.luteal: NutritionRecommendation(
      phase: CyclePhase.luteal,
      title: 'Cân Bằng Đường Huyết & Xoa Dịu Cảm Xúc (PMS)',
      description:
          'Progesterone tăng cao gây thèm ngọt và tích nước. Hãy bổ sung thực phẩm giàu Magie, Vitamin B6 để ổn định tâm trạng và giảm căng thẳng.',
      superfoods: [
        'Chocolate đen nguyên chất (≥70%)',
        'Khoai lang vàng nướng',
        'Chuối tiêu chín',
        'Gạo lứt & hạt diêm mạch (Quinoa)',
        'Hạt hướng dương & hạt mè đen',
        'Cá ngừ đại dương',
      ],
      foodsToAvoid: [
        'Đồ ngọt nhân tạo & siro ngô',
        'Đồ ăn vặt quá nhiều muối natri',
        'Cà phê buổi chiều (gây mất ngủ)',
      ],
      keyNutrients: ['Magie (Mg)', 'Vitamin B6', 'Canxi', 'Chất béo tốt'],
      teaSuggestion: 'Trà hoa oải hương (Lavender) hoặc trà táo quế ấm',
      sampleMeal: 'Khoai lang nướng ăn kèm ức gà xé và 2 thanh chocolate đen 75%.',
    ),
  };

  NutritionRecommendation getRecommendation(CyclePhase phase) {
    return _recommendations[phase] ?? _recommendations[CyclePhase.follicular]!;
  }
}
