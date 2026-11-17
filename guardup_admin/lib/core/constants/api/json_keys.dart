final class JsonKeys {
  JsonKeys._();

  // General & Standard Entity Keys
  static const String id = 'id';
  static const String name = 'name';
  static const String nameHi = 'name_hi';
  static const String description = 'description';
  static const String descriptionHi = 'description_hi';
  static const String sortOrder = 'sort_order';
  static const String displayOrder = 'display_order';
  static const String isActive = 'is_active';
  static const String status = 'status';
  static const String isRequired = 'is_required';
  static const String isResolved = 'is_resolved';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String dealTypePreference = 'deal_type_preference';

  // Media & Assets
  static const String imageUrl = 'image_url';
  static const String iconName = 'icon_name';
  static const String profileImageUrl = 'profile_image_url';

  // Legal & Help Support Keys
  static const String question = 'question';
  static const String questionHi = 'question_hi';
  static const String answer = 'answer';
  static const String answerHi = 'answer_hi';
  static const String contentType = 'content_type';
  static const String contentHtml = 'content_html';
  static const String language = 'language';
  static const String lastPublishedAt = 'last_published_at';
  static const String message = 'message';

  // User & Account Keys
  static const String role = 'role';
  static const String targetRole = 'target_role';
  static const String fullName = 'name';
  static const String email = 'email';
  static const String mobileNumber = 'phone_number';
  static const String phoneCode = 'phone_code';
  static const String registrationStatus = 'status';
  static const String userId = 'user_id';
  static const String userIdParam = 'userId';
  static const String appliesTo = 'applies_to';
  static const String businessName = 'company_name';
  static const String companyName = 'company_name';
  static const String businessEmail = 'business_email';
  static const String companyType = 'company_type';
  static const String hourlyRate = 'hourly_rate';
  static const String bio = 'bio';
  static const String services = 'services';
  static const String rating = 'rating';
  static const String capacityTons = 'capacity_tons';
  static const String addressLine1 = "address_line_1";
  static const String addressLine2 = "address_line_2";
  static const String verificationStatus = 'verification_status';
  static const String ownerId = 'owner_id';

  // Admin Settings Keys
  static const String latestIosVersion = 'latest_ios_version';
  static const String latestAndroidVersion = 'latest_android_version';
  static const String minimumIosVersion = 'minimum_ios_version';
  static const String minimumAndroidVersion = 'minimum_android_version';
  static const String updateMessageIos = 'update_message_ios';
  static const String updateMessageAndroid = 'update_message_android';
  static const String iosAppUrl = 'ios_app_url';
  static const String androidAppUrl = 'android_app_url';
  static const String supportEmail = 'support_email';
  static const String supportCallPhoneNumber = 'support_call_phone_number';
  static const String supportWhatsappPhoneNumber =
      'support_whatsapp_phone_number';
  static const String supportHours = 'support_hours';
  static const String isUnderMaintenance = 'is_under_maintenance';
  static const String maintenanceTitle = 'maintenance_title';
  static const String maintenanceMessage = 'maintenance_message';
  static const String singletonGuard = 'singleton_guard';

  // Orders & Logistics Keys
  static const String orderNumber = 'order_number';
  static const String supplyType = 'supply_type';
  static const String partyId = 'party_id';
  static const String partyName = 'party_name';
  static const String materialTypeId = 'material_type_id';
  static const String materialName = 'material_name';
  static const String totalQuantity = 'total_quantity';
  static const String dispatchedQuantity = 'dispatched_quantity';
  static const String deliveredQuantity = 'delivered_quantity';
  static const String unit = 'unit';
  static const String unitId = 'unit_id';
  static const String origin = 'origin';
  static const String destination = 'destination';
  static const String sourceLat = 'source_lat';
  static const String sourceLng = 'source_lng';
  static const String destLat = 'dest_lat';
  static const String destLng = 'dest_lng';
  static const String notes = 'notes';
  static const String orderDate = 'order_date';
  static const String expectedCompletionDate = 'expected_completion_date';

  // Order & Trip Documents Keys
  static const String orderId = 'order_id';
  static const String documentType = 'document_type';
  static const String documentName = 'document_name';
  static const String documentNumber = 'document_number';
  static const String fileUrl = 'file_url';
  static const String fileSize = 'file_size';
  static const String fileType = 'file_type';
  static const String requiredBeforeTripStatus = 'required_before_trip_status';

  // Party Keys
  static const String gst = 'gst';
  static const String type = 'type';
  static const String pincode = 'pincode';
  static const String state = 'state';
  static const String city = 'city';

  // Trips & Consignment Keys
  static const String tripNumber = 'trip_number';
  static const String tripId = 'trip_id'; // legacy reference
  static const String whoPaysFreight = 'who_pays_freight';
  static const String vehicleNumber = 'vehicle_number';
  static const String truckType = 'truck_type';
  static const String transporterId = 'transporter_id';
  static const String transporterName = 'transporter_name';
  static const String transporterContact = 'transporter_contact';
  static const String driverId = 'driver_id';
  static const String driverName = 'driver_name';
  static const String driverContact = 'driver_contact';
  static const String expectedQuantity = 'expected_quantity';
  static const String loadedQuantity = 'loaded_quantity';
  static const String quantityUnit = 'quantity_unit';
  static const String loadingDate = 'loading_date';
  static const String loadingTime = 'loading_time';
  static const String freightAmount = 'freight_amount';
  static const String agreedFreightRate = 'agreed_freight_rate';
  static const String estimatedFreight = 'estimated_freight';
  static const String advancePaid = 'advance_paid';
  static const String balanceFreight = 'balance_freight';
  static const String originCity = 'origin_city';
  static const String originState = 'origin_state';
  static const String originPincode = 'origin_pincode';
  static const String destCity = 'dest_city';
  static const String destState = 'dest_state';
  static const String destPincode = 'dest_pincode';
  static const String distanceKm = 'distance_km';
  static const String truckId = 'truck_id';
  static const String bodyType = 'body_type';
  static const String tripType = 'trip_type';
  static const String podDocumentUrl = 'pod_document_url';
  static const String podUploadedAt = 'pod_uploaded_at';
  static const String actualDepartureAt = 'actual_departure_at';
  static const String actualArrivalAt = 'actual_arrival_at';

  // Trip Timeline Milestone Keys
  static const String arrivedAt = 'arrived_at';
  static const String estimatedDeliveryAt = 'estimated_delivery_at';
  static const String actualLoadQuantity = 'actual_load_quantity';
  static const String loadedNote = 'loaded_note';
  static const String dispatchedAt = 'dispatched_at';
  static const String gatePassNumber = 'gate_pass_number';
  static const String dispatchedLocation = 'dispatched_location';
  static const String dispatchedNote = 'dispatched_note';
  static const String lastLocationLat = 'last_location_lat';
  static const String lastLocationLng = 'last_location_lng';
  static const String transitedAt = 'transited_at';
  static const String transitedLocation = 'transited_location';
  static const String transitedNote = 'transited_note';
  static const String deliveredAt = 'delivered_at';
  static const String deliveredNote = 'delivered_note';
  static const String completedAt = 'completed_at';
  static const String completedNote = 'completed_note';

  // Orders Location Keys
  static const String originZip = 'origin_zip';
  static const String destZip = 'dest_zip';
  static const String originCountry = 'origin_country';
  static const String destCountry = 'dest_country';

  // Device & Push Notification Keys
  static const String token = 'token';
  static const String platform = 'platform';
  static const String languageCode = 'language_code';
  static const String lastActiveAt = 'last_active_at';
  static const String title = 'title';
  static const String titleHi = 'title_hi';
  static const String body = 'body';
  static const String bodyHi = 'body_hi';
  static const String data = 'data';
  static const String isRead = 'is_read';
  static const String readAt = 'read_at';

  // Payments Keys
  static const String paymentNumber = 'payment_number';
  static const String recordedBy = 'recorded_by';
  static const String transactionCategory = 'transaction_category';
  static const String transactionType = 'transaction_type';
  static const String amount = 'amount';
  static const String currency = 'currency';
  static const String paymentMethod = 'payment_method';
  static const String paymentStatus = 'payment_status';
  static const String referenceType = 'reference_type';
  static const String referenceId = 'reference_id';
  static const String recipientId = 'recipient_id';
  static const String recipientLabel = 'recipient_label';
  static const String referenceNo = 'reference_no';
  static const String remark = 'remark';
  static const String proofMediaUrl = 'proof_media_url';
  static const String razorpayOrderId = 'razorpay_order_id';
  static const String razorpayPaymentId = 'razorpay_payment_id';
  static const String razorpaySignature = 'razorpay_signature';
  static const String razorpayPayload = 'razorpay_payload';
  static const String razorpayStatus = 'razorpay_status';
  static const String paymentDate = 'payment_date';
  static const String payments = 'payments';
}
