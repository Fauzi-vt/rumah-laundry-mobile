class ApiConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://ingxtyqcqdiidhievrox.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImluZ3h0eXFjcWRpaWRoaWV2cm94Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3Mzg1NjAsImV4cCI6MjA5MzMxNDU2MH0.AeIPS280yVvnsp0C3dF8XesxVEpQdNWd3faKnOFfP5k';

  // Tracking (Public)
  // Anda bisa menyimpan ini jika masih menggunakan tracking via URL manual
  static String track(String invoiceCode) => '$supabaseUrl/track/$invoiceCode';
}
