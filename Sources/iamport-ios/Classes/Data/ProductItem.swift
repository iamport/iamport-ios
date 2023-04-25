//
// Created by BingBong on 2021/01/06.
//

import Foundation
import Then

public class BaseProduct: Codable, Then {
    public init() {}
}

public class ProductItem: BaseProduct {
    public var categoryType: String?
    public var categoryId: String?
    public var uid: String?
    public var name: String?
    public var payReferrer: String?
    public var startDate: String?
    public var endDate: String?
    public var sellerId: String?
    public var count: Int?

    private enum CodingKeys: String, CodingKey {
        case categoryType, categoryId, uid, name, payReferrer,
             startDate, endDate, sellerId, count
    }

    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if categoryType != nil {
            try container.encode(categoryType, forKey: .categoryType)
        }
        if categoryId != nil {
            try container.encode(categoryId, forKey: .categoryId)
        }
        if uid != nil {
            try container.encode(uid, forKey: .uid)
        }
        if name != nil {
            try container.encode(name, forKey: .name)
        }
        if payReferrer != nil {
            try container.encode(payReferrer, forKey: .payReferrer)
        }
        if startDate != nil {
            try container.encode(startDate, forKey: .startDate)
        }
        if endDate != nil {
            try container.encode(endDate, forKey: .endDate)
        }
        if sellerId != nil {
            try container.encode(sellerId, forKey: .sellerId)
        }
        if count != nil {
            try container.encode(count, forKey: .count)
        }
    }
}

public class ProductItemForOrder: BaseProduct {
    public var id: String? // 상품고유ID
    public var merchantProductId: String? // 상품관리ID(필요한 경우만 선언. 정의하지 않으면 id값과 동일한 값을 자동 적용합니다)
    public var ecMallProductId: String? // 지식쇼핑상품관리ID(필요한 경우만 선언. 정의하지 않으면 id값과 동일한 값을 자동 적용합니다)
    public var name: String? // 상품명
    public var basePrice: Int? // 상품가격
    public var taxType: String? // 부가세 부과 여부(TAX or TAX_FREE)
    public var quantity: Int? // 상품구매수량
    public var infoUrl: String? // 상품상세페이지 URL
    public var imageUrl: String? // 상품 Thumbnail 이미지 URL
    public var giftName: String? // 해당상품 구매시 제공되는 사은품 명칭(없으면 정의하지 않음)
    public var options: [ProductOption]? // 구매자가 선택한 상품 옵션에 대한 상세 정보
    public var supplements: [Supplement]?
    public var shipping: Shipping? // 상품 배송관련 상세 정보

    private enum CodingKeys: String, CodingKey {
        case id, merchantProductId, ecMallProductId, name, basePrice,
             taxType, quantity, infoUrl, imageUrl, giftName, options, supplements, shipping
    }

    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if id != nil {
            try container.encode(id, forKey: .id)
        }
        if merchantProductId != nil {
            try container.encode(merchantProductId, forKey: .merchantProductId)
        }
        if ecMallProductId != nil {
            try container.encode(ecMallProductId, forKey: .ecMallProductId)
        }
        if name != nil {
            try container.encode(name, forKey: .name)
        }
        if basePrice != nil {
            try container.encode(basePrice, forKey: .basePrice)
        }
        if taxType != nil {
            try container.encode(taxType, forKey: .taxType)
        }
        if quantity != nil {
            try container.encode(quantity, forKey: .quantity)
        }
        if infoUrl != nil {
            try container.encode(infoUrl, forKey: .infoUrl)
        }
        if imageUrl != nil {
            try container.encode(imageUrl, forKey: .imageUrl)
        }
        if giftName != nil {
            try container.encode(giftName, forKey: .giftName)
        }
        if options != nil {
            try container.encode(options, forKey: .options)
        }
        if supplements != nil {
            try container.encode(supplements, forKey: .supplements)
        }
        if shipping != nil {
            try container.encode(shipping, forKey: .shipping)
        }
    }
}

// 확실치 않은 정보들은 nullable 처리.. 어차피 네이버가 따로 검수!
public class ProductOption: Codable, Then {
    public var optionQuantity: Int?
    public var optionPrice: Int?
    public var selectionCode: String?
    public var selections: [Selection]?
    public init() {}
}

public class Selection: Codable, Then {
    public var code: String?
    public var label: String?
    public var value: String?
    public init() {}
}

public class Supplement: Codable, Then {
    public var id: String? // 추가구성품의 ID
    public var name: String? // 추가구성품 상품명
    public var price: Int? // 추가구성품 가격
    public var quantity: Int? // 추가구성품 수량
    public init() {}
}

public class Shipping: Codable, Then {
    public var groupId: String?
    public var method: String?
    public var baseFee: Int?
    public var feeRule: [FeeRule]?
    public var feePayType: String?
    public init() {}
}

public class FeeRule: Codable, Then {
    public var freeByThreshold: Int?
    public init() {}
}

/**

 Json 로그로 확인해보기

         let productItem = ProductItem().then {
             $0.name = "name"
             $0.uid = "uid"
             $0.payReferrer = "uid"
             $0.count = 3
         }

         let productItemForOrder = ProductItemForOrder().then {
             $0.name = "name"
             $0.merchantProductId = "merchantProductId"
             $0.taxType = "taxType"
             $0.imageUrl = "http://imageUrlimageUrl"
             $0.basePrice = 3
             $0.quantity = 5

             $0.options = [
                 ProductOption().then { option in
                     option.optionQuantity = 888
                     option.optionPrice = 555
                     option.selections = [
                         Selection().then { selection in
                             selection.code = "0"
                             selection.value = "레드"
                             selection.label = "빨간맛"
                         },
                         Selection().then { selection in
                             selection.code = "1"
                             selection.value = "그린"
                             selection.label = "초록맛"
                         },

                         Selection().then { selection in
                             selection.code = "2"
                             selection.value = "블루"
                             selection.label = "파란맛"
                         }
                     ]
                 }
             ]
             $0.supplements = [
                 Supplement().then { supplement in
                     supplement.id = "id"
                     supplement.name = "name"
                     supplement.price = 239847329
                 }
             ]
             $0.shipping = Shipping().then {
                 $0.groupId = "groupId"
                 $0.baseFee = 999
                 $0.feeRule = [FeeRule().then {
                     $0.freeByThreshold = 1
                 }, FeeRule().then {
                     $0.freeByThreshold = 2
                 }, FeeRule().then {
                     $0.freeByThreshold = 3
                 }]
             }

         }

         request.naverProducts = [productItem, productItem, productItemForOrder, productItemForOrder]

         let encoder = JSONEncoder()
         encoder.outputFormatting = .prettyPrinted
         let jsonData = try? encoder.encode(request)
         debugPrint("====================")
         if let json = jsonData,
            let request = String(data: json, encoding: .utf8) {
             debugPrint(request)
         }
         debugPrint("====================")

  */
