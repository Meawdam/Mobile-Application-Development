import 'dart:typed_data';

import 'package:frontend/model/asset/asset_model.dart';
import 'package:frontend/model/borrow/borrow_model.dart';
import 'package:frontend/model/wallet/wallet_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/asset_api.dart';
import 'package:frontend/services/borrow_api.dart';
import 'package:frontend/services/wallet_api.dart';

AssetModel sampleAsset({
  int id = 1,
  int ownerId = 10,
  String name = 'Canon Camera',
  String description = 'Good condition',
  String status = 'ready',
  String approval = 'approved',
  num downPayment = 500,
  String returnBefore = '2030-12-31',
  int price = 100,
  String pickupPoint = 'Canteen',
  String? image = '/uploads/cam.jpg',
  String? ownerUsername = 'lender1',
}) {
  return AssetModel(
    id: id,
    ownerId: ownerId,
    ownerUsername: ownerUsername,
    image: image,
    name: name,
    description: description,
    status: status,
    approval: approval,
    downPayment: downPayment,
    returnBefore: returnBefore,
    price: price,
    pickupPoint: pickupPoint,
  );
}

BorrowModel sampleBorrow({
  int id = 1,
  int assetId = 1,
  String status = 'borrowed',
  String paymentStatus = 'paid',
  int rentalDays = 3,
  num? deposit = 500,
  num? totalAmount = 800,
  num? pricePerDay = 100,
  num? rentalSubtotal = 300,
  String? assetName = 'Canon Camera',
  String? pickupDate = '2026-11-12',
  String? plannedReturnDate = '2026-11-14',
}) {
  return BorrowModel(
    id: id,
    assetId: assetId,
    assetName: assetName,
    pickupDate: pickupDate,
    plannedReturnDate: plannedReturnDate,
    rentalDays: rentalDays,
    pricePerDay: pricePerDay,
    rentalSubtotal: rentalSubtotal,
    deposit: deposit,
    totalAmount: totalAmount,
    status: status,
    paymentStatus: paymentStatus,
  );
}

class FakeAssetApi extends AssetApi {
  FakeAssetApi({
    List<AssetModel>? available,
    List<AssetModel>? mine,
    AssetModel? byId,
    this.throwOnGet = false,
  })  : available = available ?? [sampleAsset()],
        mine = mine ?? [sampleAsset()],
        byId = byId ?? sampleAsset();

  List<AssetModel> available;
  List<AssetModel> mine;
  AssetModel byId;
  bool throwOnGet;
  bool created = false;
  bool updated = false;
  final List<int> deletedIds = [];

  @override
  Future<List<AssetModel>> getAvailableAssets({String? query}) async {
    if (throwOnGet) {
      throw const ApiException(500, 'assets unavailable');
    }
    if (query == null || query.isEmpty) return List.of(available);
    return available
        .where((a) => a.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<AssetModel>> getMyAssets() async => List.of(mine);

  @override
  Future<AssetModel> getAssetById(int id) async {
    if (throwOnGet) {
      throw const ApiException(404, 'asset not found');
    }
    if (byId.id != id) {
      throw const ApiException(404, 'asset not found');
    }
    return byId;
  }

  @override
  Future<AssetModel> createAsset({
    required String name,
    required String description,
    required String downPayment,
    required String price,
    required String pickupPoint,
    required String returnBefore,
    required Uint8List imageBytes,
    required String imageFilename,
  }) async {
    created = true;
    return sampleAsset(
      name: name,
      description: description,
      downPayment: num.parse(downPayment),
      price: int.parse(price),
      pickupPoint: pickupPoint,
      returnBefore: returnBefore,
    );
  }

  @override
  Future<AssetModel> updateAsset({
    required int id,
    required String name,
    required String description,
    required String downPayment,
    required String price,
    required String pickupPoint,
    required String returnBefore,
  }) async {
    updated = true;
    byId = sampleAsset(
      id: id,
      name: name,
      description: description,
      downPayment: num.parse(downPayment),
      price: int.parse(price),
      pickupPoint: pickupPoint,
      returnBefore: returnBefore,
    );
    return byId;
  }

  @override
  Future<void> deleteAsset(int id) async {
    deletedIds.add(id);
    mine.removeWhere((a) => a.id == id);
  }
}

class FakeBorrowApi extends BorrowApi {
  FakeBorrowApi({
    List<BorrowModel>? myBorrows,
    List<BorrowModel>? lending,
    BorrowModel? detail,
  })  : myBorrows = myBorrows ?? [sampleBorrow()],
        lending = lending ?? [sampleBorrow(status: 'returned_pending')],
        detail = detail ?? sampleBorrow();

  List<BorrowModel> myBorrows;
  List<BorrowModel> lending;
  BorrowModel detail;
  bool throwOnPay = false;
  int? lastPaidId;
  final List<int> cancelled = [];
  final List<int> returnRequested = [];
  final List<int> returnConfirmed = [];

  @override
  Future<BorrowModel> requestBorrow({
    required int assetId,
    required String pickupDate,
    required String returnDate,
  }) async {
    detail = sampleBorrow(
      assetId: assetId,
      status: 'requested',
      paymentStatus: 'unpaid',
      pickupDate: pickupDate,
      plannedReturnDate: returnDate,
    );
    return detail;
  }

  @override
  Future<BorrowPayResult> pay(int borrowId) async {
    if (throwOnPay) {
      throw const ApiException(400, 'payment failed');
    }
    lastPaidId = borrowId;
    return BorrowPayResult(
      borrowId: borrowId,
      walletBalance: 200,
      totalAmount: detail.totalAmount,
    );
  }

  @override
  Future<BorrowModel> getBorrowById(int id) async {
    if (detail.id != id) {
      throw const ApiException(404, 'borrow not found');
    }
    return detail;
  }

  @override
  Future<List<BorrowModel>> getMyBorrows() async => List.of(myBorrows);

  @override
  Future<List<BorrowModel>> getMyLendingBorrows() async => List.of(lending);

  @override
  Future<void> cancel(int borrowId) async {
    cancelled.add(borrowId);
    myBorrows.removeWhere((b) => b.id == borrowId);
  }

  @override
  Future<void> requestReturn(int borrowId) async {
    returnRequested.add(borrowId);
    detail = sampleBorrow(id: borrowId, status: 'returned_pending');
    myBorrows = myBorrows
        .map(
          (b) => b.id == borrowId
              ? sampleBorrow(id: borrowId, status: 'returned_pending')
              : b,
        )
        .toList();
  }

  @override
  Future<void> confirmReturn(int borrowId) async {
    returnConfirmed.add(borrowId);
    detail = sampleBorrow(id: borrowId, status: 'returned_confirmed');
    lending = lending
        .map(
          (b) => b.id == borrowId
              ? sampleBorrow(id: borrowId, status: 'returned_confirmed')
              : b,
        )
        .toList();
  }
}

class FakeWalletApi extends WalletApi {
  FakeWalletApi({this.balance = 1000});

  int balance;

  @override
  Future<WalletModel> getWallet() async => WalletModel(balance: balance);

  @override
  Future<WalletModel> topUp(int amount) async {
    if (amount <= 0) {
      throw const ApiException(400, 'amount must be a positive whole number');
    }
    balance += amount;
    return WalletModel(balance: balance);
  }
}
