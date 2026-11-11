import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "nombre", ascending: true)],
        animation: .default
    ) private var productos: FetchedResults<Producto>

    @State private var nombre = ""
    @State private var cantidad = ""
    @State private var seccion = "Electricidad"
    @State private var busqueda = ""
    @State private var seleccionado: Producto?
    @State private var mensaje = ""
    @State private var mostrarAlerta = false
    @State private var confirmarEliminar = false

    private let secciones = ["Electricidad", "Plomeria", "Cerrajeria", "Jardineria", "Tornilleria", "Construccion"]

    private var productosFiltrados: [Producto] {
        guard !busqueda.isEmpty else { return Array(productos) }
        return productos.filter {
            ($0.nombre ?? "").localizedCaseInsensitiveContains(busqueda)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos del producto") {
                    TextField("Nombre del producto", text: $nombre)
                    TextField("Cantidad", text: $cantidad)
                        .keyboardType(.numberPad)
                    Picker("Sección", selection: $seccion) {
                        ForEach(secciones, id: \.self) { opcion in
                            Text(opcion).tag(opcion)
                        }
                    }
                }

                Section("Operaciones") {
                    Button("Guardar nuevo") { guardarProducto() }
                    Button("Buscar por nombre") { buscarProducto() }
                    Button("Modificar") { modificarProducto() }
                        .disabled(seleccionado == nil)
                    Button("Eliminar", role: .destructive) { confirmarEliminar = true }
                        .disabled(seleccionado == nil)
                    Button("Nuevo / Limpiar") { iniciarCampos() }
                }

                Section("Inventario") {
                    TextField("Filtrar productos", text: $busqueda)
                    ForEach(productosFiltrados, id: \.objectID) { producto in
                        Button {
                            seleccionarProducto(producto)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(producto.nombre ?? "Sin nombre")
                                        .font(.headline)
                                    Text(producto.seccion ?? "Sin sección")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(producto.cantidad) unidades")
                                    .foregroundStyle(.primary)
                                if seleccionado?.objectID == producto.objectID {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                        }
                        .tint(.primary)
                    }
                }
            }
            .navigationTitle("Ferretería")
            .alert("Aviso", isPresented: $mostrarAlerta) {
                Button("Aceptar", role: .cancel) { }
            } message: {
                Text(mensaje)
            }
            .confirmationDialog("¿Eliminar el producto seleccionado?", isPresented: $confirmarEliminar, titleVisibility: .visible) {
                Button("Eliminar", role: .destructive) { eliminarProducto() }
                Button("Cancelar", role: .cancel) { }
            }
        }
    }

    private func avisar(_ texto: String) {
        mensaje = texto
        mostrarAlerta = true
    }

    private func datosValidos() -> (String, Int64)? {
        let nombreLimpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nombreLimpio.isEmpty else {
            avisar("Escribe el nombre del producto.")
            return nil
        }
        guard let numero = Int64(cantidad), numero >= 0 else {
            avisar("La cantidad debe ser un número entero mayor o igual a cero.")
            return nil
        }
        return (nombreLimpio, numero)
    }

    private func guardarProducto() {
        guard let (nombreLimpio, numero) = datosValidos() else { return }
        guard !productos.contains(where: { ($0.nombre ?? "").localizedCaseInsensitiveCompare(nombreLimpio) == .orderedSame }) else {
            avisar("Ya existe un producto con ese nombre.")
            return
        }
        let producto = Producto(context: viewContext)
        producto.id = UUID()
        producto.nombre = nombreLimpio
        producto.cantidad = numero
        producto.seccion = seccion
        do {
            try viewContext.save()
            iniciarCampos()
            avisar("Producto guardado correctamente.")
        } catch {
            viewContext.rollback()
            avisar("No se pudo guardar: \(error.localizedDescription)")
        }
    }

    private func buscarProducto() {
        let texto = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty else {
            avisar("Escribe un nombre para buscar.")
            return
        }
        if let producto = productos.first(where: { ($0.nombre ?? "").localizedCaseInsensitiveCompare(texto) == .orderedSame }) {
            seleccionarProducto(producto)
        } else {
            avisar("No se encontró el producto.")
        }
    }

    private func seleccionarProducto(_ producto: Producto) {
        seleccionado = producto
        nombre = producto.nombre ?? ""
        cantidad = String(producto.cantidad)
        seccion = producto.seccion ?? secciones[0]
    }

    private func modificarProducto() {
        guard let producto = seleccionado else { return }
        guard let (nombreLimpio, numero) = datosValidos() else { return }
        guard !productos.contains(where: {
            $0.objectID != producto.objectID &&
            ($0.nombre ?? "").localizedCaseInsensitiveCompare(nombreLimpio) == .orderedSame
        }) else {
            avisar("Otro producto ya tiene ese nombre.")
            return
        }
        producto.nombre = nombreLimpio
        producto.cantidad = numero
        producto.seccion = seccion
        do {
            try viewContext.save()
            iniciarCampos()
            avisar("Producto modificado correctamente.")
        } catch {
            viewContext.rollback()
            avisar("No se pudo modificar: \(error.localizedDescription)")
        }
    }

    private func eliminarProducto() {
        guard let producto = seleccionado else { return }
        viewContext.delete(producto)
        do {
            try viewContext.save()
            iniciarCampos()
            avisar("Producto eliminado correctamente.")
        } catch {
            viewContext.rollback()
            avisar("No se pudo eliminar: \(error.localizedDescription)")
        }
    }

    private func iniciarCampos() {
        nombre = ""
        cantidad = ""
        seccion = secciones[0]
        busqueda = ""
        seleccionado = nil
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
