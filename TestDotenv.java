import io.github.cdimascio.dotenv.Dotenv;
public class TestDotenv {
    public static void main(String[] args) {
        try {
            Dotenv dotenv = Dotenv.configure().directory(".").load();
            System.out.println("Loaded DB_URL: " + dotenv.get("DB_URL"));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
