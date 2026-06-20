import 'package:barter/features/on_boarding/on_boarding_screen.dart';
import 'package:barter/features/splash/splash_screen.dart';
import 'package:barter/features/trade/trade_initiation_screen.dart';
import 'package:barter/features/products/models/product_model.dart';
import 'package:flutter/material.dart';

import '../../features/authentication/login/login.dart';
import '../../features/authentication/login/otp_screen.dart';
import '../../features/authentication/register/register.dart';
import '../../features/authentication/register/phone_otp_screen.dart';
import '../../features/create_product/create_product.dart';
import '../../features/main_layout/main_layout.dart';
import '../../features/on_boarding/start_screen.dart';
import '../../features/products/product_details_screen.dart';
import '../../features/products/products_screen.dart';

import '../../features/trade/trade_management_screen.dart';
import '../../features/profile/trade_history_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/favourites/favourites_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/chat/chat_list_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/reviews/leave_review_screen.dart';
import '../../features/payment/checkout_screen.dart';
import '../../features/premium/screens/premium_subscription_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';
import '../../features/admin/screens/admin_withdrawals_screen.dart';
import '../../features/delivery/screens/agent_dashboard_screen.dart';
import '../../features/delivery/screens/delivery_status_screen.dart';

class RoutesManager {
  static const String register = "/register";
  static const String login = "/login";
  static const String otpVerification = "/otpVerification";
  static const String phoneOtpVerification = "/phoneOtpVerification";
  static const String mainLayout = "/mainLayout";
  static const String createProduct = "/createProduct";
  static const String productDetails = "/productDetails";
  static const String favourites = "/favourites";
  static const String onboarding = "/onboarding";
  static const String startScreen = "/startScreen";
  static const String splashScreen = "/splashScreen";
  static const String initiateTrade = '/initiate-trade';
  static const String tradeManagement = '/trade-management';
  static const String tradeDetails = '/trade-details';
  static const String tradeHistory = '/trade-history';
  static const String chat = '/chat';
  static const String chatList = '/chat-list';
  static const String adminDashboard = '/admin-dashboard';
  static const String notifications = '/notifications';
  static const String leaveReview = '/leave-review';
  static const String editProfile = '/edit-profile';
  static const String myProducts = '/myProducts';
  static const String checkout = '/checkout';
  static const String premiumSubscription = '/premium-subscription';
  static const String wallet = '/wallet';
  static const String adminWithdrawals = '/admin-withdrawals';
  static const String agentDashboard = '/agent-dashboard';
  static const String deliveryStatus = '/delivery-status';

  static Route? router(RouteSettings setting) {
    switch (setting.name) {
      case register:
        {
          return MaterialPageRoute(builder: (context) => Register());
        }
      case login:
        {
          return MaterialPageRoute(builder: (context) => Login());
        }
      case otpVerification:
        {
          final args = setting.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              email: args['email'],
              generatedOtp: args['generatedOtp'],
            ),
          );
        }
      case phoneOtpVerification:
        {
          final args = setting.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PhoneOtpScreen(
              arguments: args,
            ),
          );
        }

      case mainLayout:
        {
          return MaterialPageRoute(builder: (context) => MainLayout());
        }
      case createProduct:
        {
          final dynamic args = setting.arguments;
          if (args is ProductModel) {
            return MaterialPageRoute(
              builder: (context) => CreateProduct(product: args),
            );
          } else if (args is ProductType) {
            return MaterialPageRoute(
              builder: (context) => CreateProduct(initialType: args),
            );
          }
          return MaterialPageRoute(
            builder: (context) => CreateProduct(),
          );
        }
      case initiateTrade:
        {
          final ProductModel targetProduct = setting.arguments as ProductModel;
          return MaterialPageRoute(
            builder: (context) =>
                InitiateTradeScreen(targetProduct: targetProduct),
          );
        }

      case tradeManagement:
        return MaterialPageRoute(
          builder: (context) => const TradeManagementScreen(),
        );

      case productDetails:
        {
          final args = setting.arguments;
          ProductModel? initialProduct;
          String productId = '';

          if (args is ProductModel) {
            initialProduct = args;
            productId = args.id;
          } else if (args is String) {
            productId = args;
          } else if (args is Map) {
            final productArg = args['product'];
            final productIdArg = args['productId'];
            if (productArg is ProductModel) {
              initialProduct = productArg;
            }
            if (productIdArg is String) {
              productId = productIdArg;
            }
            productId =
                productId.isNotEmpty ? productId : initialProduct?.id ?? '';
          }

          return MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              productId: productId,
              initialProduct: initialProduct,
            ),
          );
        }

      case onboarding:
        {
          return MaterialPageRoute(builder: (context) => OnBoardingScreen());
        }
      case startScreen:
        {
          return MaterialPageRoute(builder: (context) => StartScreen());
        }
      case splashScreen:
        {
          return MaterialPageRoute(builder: (context) => SplashScreen());
        }
      case tradeHistory:
        {
          return MaterialPageRoute(
            builder: (context) => const TradeHistoryScreen(),
          );
        }

      case favourites:
        {
          return MaterialPageRoute(
            builder: (context) => const FavouritesScreen(),
          );
        }
      case chat:
        {
          final args = setting.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ChatScreen(
              tradeId: args['tradeId'], // Optional
              otherUserId: args['otherUserId'],
              otherUserName: args['otherUserName'],
              conversationId: args['conversationId'], // Optional
              productTitle: args['productTitle'], // Optional
              productId: args['productId'], // Optional
            ),
          );
        }
      case chatList:
        {
          return MaterialPageRoute(builder: (context) => ChatListScreen());
        }
      case adminDashboard:
        {
          return MaterialPageRoute(
            builder: (context) => const AdminDashboardScreen(),
          );
        }
      case notifications:
        {
          return MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          );
        }
      case leaveReview:
        {
          final args = setting.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => LeaveReviewScreen(
              trade: args['trade'],
              targetUserId: args['targetUserId'],
              targetUserName: args['targetUserName'],
            ),
          );
        }
      case editProfile:
        {
          return MaterialPageRoute(
              builder: (context) => const EditProfileScreen());
        }
      case myProducts:
        {
          return MaterialPageRoute(
              builder: (context) => const ProductsScreen());
        }
      case checkout:
        {
          final product = setting.arguments as ProductModel;
          return MaterialPageRoute(
            builder: (context) => CheckoutScreen(product: product),
          );
        }
      case premiumSubscription:
        {
          return MaterialPageRoute(
            builder: (context) => const PremiumSubscriptionScreen(),
          );
        }
      case wallet:
        {
          return MaterialPageRoute(
            builder: (context) => const WalletScreen(),
          );
        }
      case adminWithdrawals:
        {
          return MaterialPageRoute(
            builder: (context) => const AdminWithdrawalsScreen(),
          );
        }
      case agentDashboard:
        {
          return MaterialPageRoute(
            builder: (context) => const AgentDashboardScreen(),
          );
        }
      case deliveryStatus:
        {
          final orderId = setting.arguments as String;
          return MaterialPageRoute(
            builder: (context) => DeliveryStatusScreen(orderId: orderId),
          );
        }
    }
    return null;
  }
}
