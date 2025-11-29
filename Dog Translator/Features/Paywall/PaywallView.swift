import SwiftUI
import StoreKit
import Combine

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var viewModel: DogViewModel
    @EnvironmentObject var storeManager: StoreManager

    @State private var selectedProductID: String = "com.god.dogtranslator.pro.monthly"

    var body: some View {
        MainBackgroundView {
            VStack(spacing: 0) {

                HStack {
                    Button("Restore") {

                        Task {
                            await storeManager.restorePurchases()
                            if storeManager.isPro {
                                dismiss()
                            }
                        }
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.appBlue)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                LinearGradient(
                                    colors: [Color.appPurple, Color.appBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: Color.appPurple.opacity(0.4), radius: 10, y: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 30) {

                        VStack(spacing: 12) {
                            Image("dog_house_header")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                            Text("Pro Access")
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                                .foregroundColor(.appBlue)
                            Text("Upgrade to Pro to get all these great benefits:")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .padding(.top, 10)

                        VStack(alignment: .leading, spacing: 20) {
                            BenefitRow(icon: "waveform", text: "Unlimited Sounds")
                            BenefitRow(icon: "text.bubble.fill", text: "Unlimited AI Translations")
                            BenefitRow(icon: "figure.walk", text: "Full Walk History")
                            BenefitRow(icon: "brain.head.profile", text: "Unlimited Memories")
                            BenefitRow(icon: "star.fill", text: "All Future Features")
                        }
                        .padding(.horizontal, 40)
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    HStack(spacing: 10) {

                        ForEach(storeManager.products) { product in
                            SubscriptionOfferCard(
                                product: product,
                                isSelected: product.id == selectedProductID
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selectedProductID = product.id
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Button {

                        Task {

                            if let product = storeManager.products.first(where: { $0.id == selectedProductID }) {
                                await storeManager.purchase(product)

                                if storeManager.isPro {
                                    dismiss()
                                }
                            }
                        }
                    } label: {
                        Text("CONTINUE")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appBlue)
                            .clipShape(Capsule())
                            .shadow(color: .appPurple.opacity(0.4), radius: 10, y: 5)
                    }
                    .disabled(storeManager.isLoading)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    HStack(spacing: 20) {
                        Link("Privacy Policy", destination: URL(string: "https://telegra.ph/Privacy-Policy-11-03-398")!)
                        Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
                    .padding(.top, 5)
                }
            }

            .onAppear {
                Task {
                    await storeManager.loadProducts()

                    if storeManager.products.first(where: { $0.id.contains("monthly") }) != nil {
                        selectedProductID = "com.god.dogtranslator.pro.monthly"
                    } else if let firstProduct = storeManager.products.first {

                        selectedProductID = firstProduct.id
                    }
                }
            }

            .overlay(
                storeManager.isLoading ?
                Color.black.opacity(0.5)
                    .overlay(ProgressView().tint(.white))
                    .ignoresSafeArea()
                : nil
            )
        }
    }
}

private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.appPurple)
                .frame(width: 30)

            Text(text)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.appBlue)

            Spacer()
        }
    }
}

private struct SubscriptionOfferCard: View {
    let product: Product
    let isSelected: Bool

    private var combinedPriceText: String {
        return product.displayPrice
    }

    private var planName: String {
        return product.displayName.uppercased().replacingOccurrences(of: "1 ", with: "")
    }

    var body: some View {
        VStack(spacing: 8) {

            Text(planName)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(isSelected ? .white : .appBlue)

            Text(combinedPriceText)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(isSelected ? .white : .appPurple)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Spacer().frame(height: 5)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(
            ZStack {
                if isSelected {
                    LinearGradient(
                        colors: [Color.appPurple, Color.appBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    Color.elementBackground
                }
            }
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isSelected ? Color.clear : Color.appBlue.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: (isSelected ? Color.appPurple : Color.black).opacity(0.2), radius: 8, y: 4)
        .scaleEffect(isSelected ? 1.0 : 0.95)
        .overlay(

            ZStack {
                if product.id.contains("monthly") {
                    Text("Best Offer")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.appPurple)
                        .clipShape(Capsule())
                        .offset(y: -15)
                }
            },
            alignment: .top
        )
    }
}

extension Product.SubscriptionPeriod.Unit {
    var unitDisplayName: String {
        switch self {
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return ""
        }
    }
}
