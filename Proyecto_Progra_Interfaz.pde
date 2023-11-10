import processing.data.Table;
import processing.data.TableRow;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.ResultSet;
import java.sql.Statement;
import javax.swing.JOptionPane;
import java.util.Arrays;

Connection dbConnection;
Table tabla;
String nombreTabla;
String columnaSeleccionada1;
String columnaSeleccionada2;

void setup() {
  size(800, 600);

  // Interfaz para que el usuario seleccione la tabla y columnas
  nombreTabla = selectTable();
  columnaSeleccionada1 = selectColumn("Selecciona la primera columna (letras o números):");
  columnaSeleccionada2 = selectNumericColumn("Selecciona la segunda columna (números):");
  
  // Conectar a la base de datos MySQL
  String url = "jdbc:mysql://localhost:3306/proferros";
  String user = "root";
  String password = "root";

  try {
    dbConnection = DriverManager.getConnection(url, user, password);
    println("Conexión a la base de datos exitosa.");

    // Ejecutar una consulta SQL para recuperar los datos de la tabla
    java.sql.Statement stmt = dbConnection.createStatement();

    // Construir la consulta SQL con las columnas seleccionadas
    ResultSet rs = stmt.executeQuery("SELECT `" + columnaSeleccionada1 + "`, `" + columnaSeleccionada2 + "` FROM `" + nombreTabla + "`");

    // Crear una tabla de Processing y agregar los datos de la base de datos
    tabla = new Table();
    tabla.addColumn(columnaSeleccionada1);
    tabla.addColumn(columnaSeleccionada2);

    while (rs.next()) {
      TableRow newRow = tabla.addRow();
      newRow.setString(columnaSeleccionada1, rs.getString(columnaSeleccionada1));
      newRow.setString(columnaSeleccionada2, rs.getString(columnaSeleccionada2));
    }

    // Dibujar una gráfica de barras
    background(255);

    float barWidth = 50;
    float x = 100;
    float maxCantidad = getMaxCantidad();

    for (int i = 0; i < tabla.getRowCount(); i++) {
      float cantidad = tabla.getFloat(i, columnaSeleccionada2);
      float barHeight = map(cantidad, 0, maxCantidad, 0, height - 50);

      fill(random(255), random(255), random(255));
      rect(x, height - barHeight - 25, barWidth, barHeight);
      fill(0);
      textAlign(CENTER);

      // Dividir la etiqueta en varias líneas si es demasiado larga
      String[] etiquetaDividida = splitEtiqueta(tabla.getString(i, columnaSeleccionada1), 20);
      float etiquetaY = height - 10 - (etiquetaDividida.length - 1) * 12;
      for (int j = 0; j < etiquetaDividida.length; j++) {
        text(etiquetaDividida[j], x + barWidth / 2, etiquetaY);
        etiquetaY += 12; // Incrementa la posición en Y para la siguiente línea
      }

      x += barWidth + 20;
    }
  } catch (SQLException e) {
    println("Error al conectar o recuperar datos: " + e.getMessage());
  }
}

void draw() {
  // Puedes agregar más elementos o interacciones gráficas aquí si lo deseas
}

void keyPressed() {
  if (key == 'q' || key == 'Q') {
    try {
      if (dbConnection != null) {
        dbConnection.close();
        println("Conexión cerrada.");
      }
    } catch (SQLException e) {
      println("Error al cerrar la conexión: " + e.getMessage());
    }
    exit();
  }
}

float getMaxCantidad() {
  float maxCantidad = 0;
  for (int i = 0; i < tabla.getRowCount(); i++) {
    float cantidad = tabla.getFloat(i, columnaSeleccionada2);
    if (!Float.isNaN(cantidad) && Float.isFinite(cantidad)) {
      maxCantidad = max(maxCantidad, cantidad);
    }
  }
  return maxCantidad;
}

String selectTable() {
  String[] options = {"gestion_inventario", "control_produccion", "registro_pedidos"};
  return (String) JOptionPane.showInputDialog(null, "Selecciona una tabla:", "Tabla", JOptionPane.PLAIN_MESSAGE, null, options, options[0]);
}

String selectColumn(String message) {
  String[] columnas = getColumnNames();
  return (String) JOptionPane.showInputDialog(null, message, "Columna", JOptionPane.PLAIN_MESSAGE, null, columnas, columnas[0]);
}

String selectNumericColumn(String message) {
  String[] columnasNumericas = getNumericColumnNames();
  return (String) JOptionPane.showInputDialog(null, message, "Columna Numérica", JOptionPane.PLAIN_MESSAGE, null, columnasNumericas, columnasNumericas[0]);
}

String[] getColumnNames() {
  // Obtener las columnas según la tabla elegida
  switch (nombreTabla) {
    case "gestion_inventario":
      return new String[]{"Id del producto", "Nombre del producto", "Categoria", "Marca", "Numero de modelo", "Proveedor", "Fecha de adquisicion", "Fecha de vencimiento"};
    case "control_produccion":
      return new String[]{"Id de producción", "Producto a fabricar", "Fecha de inicio produccion", "Estado de la produccion", "Observaciones"};
    case "registro_pedidos":
      return new String[]{"Fecha del pedido", "Cliente", "Productos solicitados", "Estado del pedido", "Metodo de pago", "Fecha de entrega estimada", "Direccion de entrega", "Estado de pago"};
    default:
      return new String[0];
  }
}

String[] getNumericColumnNames() {
  // Obtener las columnas numéricas según la tabla elegida
  switch (nombreTabla) {
    case "gestion_inventario":
      return new String[]{"Cantidad en stock", "Nivel minimo de stock", "Nivel maximo de stock", "Precio unitario (Q)"};
    case "control_produccion":
      return new String[]{"Cantidad a producir"};
    case "registro_pedidos":
      return new String[]{"Costo total del pedido"};
    default:
      return new String[0];
  }
}

String[] splitEtiqueta(String etiqueta, int maxCaracteres) {
  // Divide la etiqueta en varias líneas
  String[] palabras = splitTokens(etiqueta, " ");
  String lineaActual = "";
  int contadorCaracteres = 0;
  String[] lineas = new String[1];
  int indexLinea = 0;

  for (String palabra : palabras) {
    if (contadorCaracteres + palabra.length() <= maxCaracteres) {
      lineaActual += palabra + " ";
      contadorCaracteres += palabra.length() + 1;
    } else {
      // Asegúrate de que haya espacio suficiente en el array antes de intentar acceder al índice
      if (indexLinea < lineas.length) {
        lineas[indexLinea] = lineaActual.trim();
      } else {
        // Si no hay suficiente espacio, amplía el array
        lineas = append(lineas, lineaActual.trim());
      }
      lineaActual = palabra + " ";
      contadorCaracteres = palabra.length() + 1;
      indexLinea++;
    }
  }

  // Asegúrate de que haya espacio suficiente en el array antes de intentar acceder al índice
  if (indexLinea < lineas.length) {
    lineas[indexLinea] = lineaActual.trim();
  } else {
    // Si no hay suficiente espacio, amplía el array
    lineas = append(lineas, lineaActual.trim());
  }

  return lineas;
}
