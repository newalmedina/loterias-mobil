class ApiConfig {
  // Base URL apuntando al prefijo api
  static const String baseUrl = "https://lotery.el-solitions.es/api";

  // Endpoints
  static const String login = "/login";
  static const String logout = "/logout";
  static const String user = "/user";
  static const String updateProfile = "/update-profile";
  static const String validateToken = "/validate-token";

  static const String finalizarVenta = "/ventas/finalizar";
  static const String anularVenta = "/ventas/delete";
  static const String pagarVenta = "/ventas/pagar";
  static const String getVentas = "/ventas/search-venta";
  static const String findVentas = "/ventas/find";
  static const String findVentaByUuid = "/ventas/find-uuid";
  static const String ventasUserCanShow = "/ventas/user-can-show";
  static const String getResults = "/loteries/get-results";
  static const String getloteries = "/loteries/get-loteries";
  static const String getloteriesDisponibles =
      "/loteries/get-center-loteries-disponibles";
}
