import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_item.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/usecases/product_usecases.dart';
import '../../../../core/utils/printer_helper.dart';
import '../../../../core/data/hive_database.dart';

part 'billing_event.dart';
part 'billing_state.dart';

class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final GetProductByBarcodeUseCase getProductByBarcodeUseCase;

  BillingBloc({required this.getProductByBarcodeUseCase})
      : super(const BillingState()) {
    on<ScanBarcodeEvent>(_onScanBarcode);
    on<AddProductToCartEvent>(_onAddProductToCart);
    on<RemoveProductFromCartEvent>(_onRemoveProductFromCart);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<ClearCartEvent>(_onClearCart);
    on<PrintReceiptEvent>(_onPrintReceipt);
  }

  Future<void> _onScanBarcode(
      ScanBarcodeEvent event, Emitter<BillingState> emit) async {
    final result = await getProductByBarcodeUseCase(event.barcode);
    result.fold(
      (failure) =>
          emit(state.copyWith(error: 'Product not found: ${event.barcode}')),
      (product) {
        add(AddProductToCartEvent(product));
      },
    );
  }

  void _emitTransientError(Emitter<BillingState> emit, String message) {
  emit(state.copyWith(error: message));
  emit(state.copyWith(clearError: true));
}

void _onAddProductToCart(
  AddProductToCartEvent event,
  Emitter<BillingState> emit,
) {
  final cleanState = state.copyWith(error: null);

  if (event.product.stock <= 0) {
    _emitTransientError(
      emit,
      'El producto "${event.product.name}" no tiene stock disponible.',
    );
    return;
  }

  final existingIndex = cleanState.cartItems.indexWhere(
    (item) => item.product.id == event.product.id,
  );

  if (existingIndex >= 0) {
    final existingItem = cleanState.cartItems[existingIndex];
    final nextQuantity = existingItem.quantity + 1;

    if (nextQuantity > event.product.stock) {
      _emitTransientError(
        emit,
        'Solo hay ${event.product.stock % 1 == 0 ? event.product.stock.toInt() : event.product.stock} unidades disponibles de "${event.product.name}".',
      );
      return;
    }

    final updatedItems = List<CartItem>.from(cleanState.cartItems);
    updatedItems[existingIndex] =
        existingItem.copyWith(quantity: nextQuantity);

    emit(cleanState.copyWith(cartItems: updatedItems, error: null));
  } else {
    final newItem = CartItem(product: event.product);
    emit(
      cleanState.copyWith(
        cartItems: [...cleanState.cartItems, newItem],
        error: null,
      ),
    );
  }
}

  void _onRemoveProductFromCart(
      RemoveProductFromCartEvent event, Emitter<BillingState> emit) {
    final updatedList = state.cartItems
        .where((item) => item.product.id != event.productId)
        .toList();
    emit(state.copyWith(cartItems: updatedList));
  }

void _onUpdateQuantity(
  UpdateQuantityEvent event,
  Emitter<BillingState> emit,
) {
  if (event.quantity <= 0) {
    add(RemoveProductFromCartEvent(event.productId));
    return;
  }

  final index = state.cartItems.indexWhere(
    (item) => item.product.id == event.productId,
  );

  if (index >= 0) {
    final currentItem = state.cartItems[index];

    if (event.quantity > currentItem.product.stock) {
      _emitTransientError(
        emit,
        'No puedes agregar más de ${currentItem.product.stock % 1 == 0 ? currentItem.product.stock.toInt() : currentItem.product.stock} unidades de "${currentItem.product.name}".',
      );
      return;
    }

    final items = List<CartItem>.from(state.cartItems);
    items[index] = items[index].copyWith(quantity: event.quantity);
    emit(state.copyWith(cartItems: items, clearError: true));
  }
}

  void _onClearCart(ClearCartEvent event, Emitter<BillingState> emit) {
    emit(const BillingState());
  }

  Future<void> _onPrintReceipt(
      PrintReceiptEvent event, Emitter<BillingState> emit) async {
    final printerHelper = PrinterHelper();

    if (!printerHelper.isConnected) {
      final savedMac = HiveDatabase.settingsBox.get('printer_mac');
      if (savedMac != null) {
        final connected = await printerHelper.connect(savedMac);
        if (!connected) {
          emit(state.copyWith(
              error: 'Failed to auto-connect to printer!', clearError: false));
          emit(state.copyWith(clearError: true));
          return;
        }
      } else {
        emit(state.copyWith(
            error: 'Printer not connected & no saved printer found!',
            clearError: false));
        emit(state.copyWith(clearError: true));
        return;
      }
    }

    emit(state.copyWith(
        isPrinting: true, printSuccess: false, clearError: true));

    try {
      final items = state.cartItems
          .map((item) => {
                'name': item.product.name,
                'qty': item.quantity,
                'price': item.product.price,
                'total': item.total,
              })
          .toList();

      await printerHelper.printReceipt(
          shopName: event.shopName,
          address1: event.address1,
          address2: event.address2,
          phone: event.phone,
          items: items,
          total: state.totalAmount,
          footer: event.footer);

      emit(state.copyWith(isPrinting: false, printSuccess: true));
    } catch (e) {
      emit(state.copyWith(
          isPrinting: false, error: 'Print failed: $e', clearError: false));
      // Reset error instantly avoids sticky error
      emit(state.copyWith(clearError: true));
    }
  }
}
