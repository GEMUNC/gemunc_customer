import 'package:dio/dio.dart';
import 'package:eshop_plus/core/api/apiService.dart';
import 'package:eshop_plus/core/configs/appConfig.dart';

import 'package:eshop_plus/core/api/apiEndPoints.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:eshop_plus/ui/auth/repositories/authRepository.dart';

import '../models/order.dart';

class OrderRepository {
  Future<
      ({
        List<Order> orders,
        int total,
      })> getOrders({
    required int storeId,
    int? id,
    int? productId,
    int? offset,
    String? status,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    try {
      Map<String, dynamic> queryParameters = {
        ApiURL.storeIdApiKey: storeId,
        ApiURL.offsetApiKey: offset ?? 0,
        ApiURL.limitApiKey: limit,
        if (search != '' && search != null) ApiURL.searchApiKey: search,
      };
      void addIfNotNull(String key, dynamic value) {
        if (value != null) queryParameters[key] = value;
      }

      addIfNotNull(ApiURL.idApiKey, id);
      addIfNotNull(ApiURL.startDateApiKey, startDate);
      addIfNotNull(ApiURL.endDateApiKey, endDate);

      if (status != allKey && status != null) {
        queryParameters.addAll({ApiURL.activeStatusApiKey: status});
      }

    final result = await Api.get(
          url: ApiURL.getOrders,
          useAuthToken: true,
          queryParameters: queryParameters);
      return (
        orders: ((result[ApiURL.dataKey] ?? []) as List)
            .map((order) => Order.fromJson(Map.from(order ?? {})))
            .toList(),
        total: int.parse((result[ApiURL.totalKey] ?? 0).toString()),
      );
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e
            .toString()); // Re-throw the API exception with the backend message
      } else {
        // Handle any other exceptions
        throw ApiException(defaultErrorMessageKey);
      }
    }
  }

  Future<String> deleteOrder({required String orderId}) async {
    try {
      final result = await Api.delete(
          url: ApiURL.deleteOrder,
          useAuthToken: true,
          queryParameters: {ApiURL.orderIdApiKey: orderId});
      return result[ApiURL.messageKey];
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e.toString());
      } else {
        throw ApiException(defaultErrorMessageKey);
      }
    }
  }

  Future<String> getOrderInvoice({required int orderId}) async {
    try {
      final result = await Api.get(
          url: ApiURL.downloadOrderInvoice,
          useAuthToken: true,
          queryParameters: {
            ApiURL.orderIdApiKey: orderId,
            ApiURL.userIdApiKey: AuthRepository.getUserDetails().id,
          });

      return result['invoice_url'];
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e.toString());
      } else {
        throw ApiException(defaultErrorMessageKey);
      }
    }
  }

  Future<({Order order, String successMessage})> updateOrderItemStatus(
      {required Map<String, dynamic> params}) async {
    try {
      final result = await Api.post(
          body: params, url: ApiURL.updateOrderItemStatus, useAuthToken: true);

      return (
        successMessage: result[ApiURL.messageKey].toString(),
        order: Order.fromJson(Map.from(result[ApiURL.dataKey][0] ?? {}))
      );
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e.toString());
      } else {
        throw ApiException(defaultErrorMessageKey);
      }
    }
  }

  Future<String> updateOrderStatus(
      {required Map<String, dynamic> params}) async {
    try {
      final result = await Api.put(
          queryParameters: params,
          url: ApiURL.updateOrderStatus,
          useAuthToken: true);

      return result[ApiURL.messageKey].toString();
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e.toString());
      } else {
        throw ApiException(defaultErrorMessageKey);
      }
    }
  }

  Future<String> getFileDownloadLink({required int orderItemId}) async {
    try {
      final result = await Api.post(
          url: ApiURL.downloadLinkHash,
          useAuthToken: true,
          body: {ApiURL.orderItemIdApiKey: orderItemId});

      return result[ApiURL.dataKey];
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e.toString());
      } else {
        throw ApiException(defaultErrorMessageKey);
      }
    }
  }

  Future<void> downloadFile(
      {required String url,
      required String savePath,
      required CancelToken cancelToken,
      required Function updateDownloadedPercentage}) async {
    try {
      await Api.download(
          cancelToken: cancelToken,
          url: url,
          savePath: savePath,
          updateDownloadedPercentage: updateDownloadedPercentage);
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e.toString());
      } else {
        throw ApiException(defaultErrorMessageKey);
      }
    }
  }

  Future<Map<String, dynamic>> sendBankTransferProof(
      {required int orderId, required List<MultipartFile> attachments}) async {
    try {
      final result = await Api.post(
        url: ApiURL.sendBankTransferProofApi,
        useAuthToken: true,
        body: {
          ApiURL.orderIdApiKey: orderId,
          'attachments': attachments,
        },
      );
      return result;
    } catch (e) {
      if (e is ApiException) {
        throw ApiException(e.toString());
      } else {
        throw ApiException(defaultErrorMessageKey);
      }
    }
  }
}
