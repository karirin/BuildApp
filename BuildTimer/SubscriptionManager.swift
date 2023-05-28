//
//  SubscriptionManager.swift
//  BuildApp
//
//  Created by hashimo ryoya on 2023/05/02.
//

import SwiftUI
import StoreKit

class SubscriptionManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    @Published var premiumSubscription: SKProduct?
    
    func requestProducts() {
        let productIdentifiers = Set(["your_product_identifier"])
        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.premiumSubscription = response.products.first
        }
    }
    
    func purchase(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                // 購入またはリストア成功
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed, .deferred, .purchasing:
                break
            default:
                break
            }
        }
    }
}

