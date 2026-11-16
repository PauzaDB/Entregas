drop database if exists retail_project;
create database retail_project; 

create schema if not exists public;
SET search_path TO public; --Para conectar a la ruta del esquema, soluciona error "no existe relación".


create table clientes (
    id_cliente  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE,
    edad        INT NOT NULL,
    ciudad      VARCHAR(80),
    CONSTRAINT ck_clientes_edad CHECK (edad BETWEEN 18 AND 120) -- 1er CHECK: valida la edad para mayor de 18.
);

create table if not exists categorias (
    id_categoria INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre       VARCHAR(60) NOT NULL,
    descripcion  VARCHAR(200),
    CONSTRAINT uq_categorias_nombre UNIQUE (nombre), --limita el tipo de dato y los valores son distintos entre si.
    CONSTRAINT ck_categorias_nombre CHECK (char_length(trim(nombre)) > 0) --elimina espacios en blanco.
    );

create table if not exists productos (
    id_producto     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          VARCHAR(120) NOT NULL,
    id_categoria    INT NOT NULL,
    precio_unitario NUMERIC(10,2) NOT NULL,
    stock           INT NOT NULL DEFAULT 0,
    CONSTRAINT ck_productos_precio CHECK (precio_unitario > 0), --4to CHECK: cantidad vendida mayor a cero.
    CONSTRAINT ck_productos_stock  CHECK (stock >= 0), --5to CHECK: precio de venta positivo.
    CONSTRAINT fk_productos_categoria FOREIGN KEY (id_categoria)
        REFERENCES categorias (id_categoria)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

create table ventas (
    id_venta        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente      INT NOT NULL,
    id_producto     INT NOT NULL,
    cantidad        INT NOT NULL,
    precio_unitario NUMERIC(10,2) NOT NULL,  -- precio al momento de la venta
    fecha_venta     DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT ck_ventas_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_ventas_precio   CHECK (precio_unitario > 0),
    CONSTRAINT fk_ventas_cliente  FOREIGN KEY (id_cliente) --Claves foraneas
        REFERENCES clientes (id_cliente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ventas_producto FOREIGN KEY (id_producto)
        REFERENCES productos (id_producto)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

---Carga de datos--
-- Los ids se generan en orden de 1 a 5 en clientes y productos.

BEGIN; --Se ejecuta primero para iniciar la transacción. 

INSERT INTO clientes (nombre, email, edad, ciudad) values --Se ingresan valores a las tablas. 
    ('Juancito', 'juan.cito@mail.com', 18,'Buenos Aires'),
    ('Robertito',  'rober.tito@mail.com', 21, 'Córdoba'),
    ('Jorgito',  'jorgito.alfajor@mail.com', 25, 'Rosario'),
    ('Dieguito', 'diego.maradona@mail.com', 67, 'Mendoza'),
    ('Valentina Cruz', 'valen.cruz@mail.com', 33, 'La Plata');

INSERT INTO categorias (nombre, descripcion) VALUES
    ('Electrónica', 'Dispositivos y equipos electrónicos'),
    ('Accesorios',  'Accesorios y complementos'),
    ('Hogar',       'Artículos para el hogar');

INSERT INTO productos (nombre, id_categoria, precio_unitario, stock) VALUES
    ('Notebook 15',           1, 850000.00, 15),
    ('Auriculares Bluetooth', 1,  45000.00, 60),
    ('Mouse Inalámbrico',     2,  12000.00, 120),
    ('Mochila Urbana',        2,  38000.00, 40),
    ('Cafetera Express',      3, 135000.00, 25);

INSERT INTO ventas (id_cliente, id_producto, cantidad, precio_unitario, fecha_venta) values 
    (1, 1, 1, 850000.00, '2026-10-02'),
    (2, 2, 2,  45000.00, '2026-10-05'),
    (3, 3, 3,  12000.00, '2026-10-09'),
    (4, 4, 1,  38000.00, '2026-10-14'),
    (5, 5, 1, 135000.00, '2026-10-20'),
    (1, 3, 2,  12000.00, '2026-11-01');

COMMIT; --Realiza los cambios de forma permanente. 

ROLLBACK; --Deshace los cambios realizados en la transacción, si no se ejecuto el Commit.

TRUNCATE productos, clientes, categorias RESTART identity CASCADE; --Lo utilice para reinicar los autoincrementales 
--y eliminar valores de las tablas, se utilizo Cascade debido las claves foraneas. 

SELECT * FROM productos; --Consultas para verificar datos en tablas.
SELECT * FROM ventas;
SELECT * FROM clientes;
SELECT * FROM categorias;


--Pre entrega 5--
-- Las CTEs tienen que llamarse ventas_mensuales (año/mes, categoría y suma de ventas) 1er CTE.
-- Metricas_ventana (ranking de categorías por mes y running total por categoría) 2do CTE.
-- Las etiquetas del CASE WHEN tienen que ser Exitoso y Bajo el promedio, consulta final (SELECT principal).
-- Running total va con ORDER BY.

with ventas_mensuales as ( -- CTE 1: total vendido por mes (primer día del mes) y categoría
    SELECT DATE_TRUNC('month', v.fecha_venta)::DATE AS mes, --recorta la fecha del mes.
           c.nombre                                 AS categoria, 
           SUM(v.cantidad * v.precio_unitario)      AS total_ventas
    from   ventas v
    join   productos  p ON p.id_producto  = v.id_producto --Devuelve las filas de la tabla productos, se abrevia productos con p.
    join   categorias c ON c.id_categoria = p.id_categoria --y hace la unión entre las dos Id, se abrevia categorias con c.
    group by DATE_TRUNC('month', v.fecha_venta), c.nombre --Agrupa por fecha y nombre
),
metricas_ventana as (  -- CTE 2: funciones de ventana sobre los datos de la CTE anterior
    select mes, categoria, total_ventas,
           RANK() OVER (  -- Ranking de categorías dentro de cada mes donde -> 1 = la más vendida.
               PARTITION BY mes --Reinicia el contador
               ORDER BY total_ventas DESC
           ) AS ranking_mes,
           SUM(total_ventas) OVER ( -- Total acumulado (running total) por categoría a lo largo del tiempo
               PARTITION BY categoria
               ORDER BY mes
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW --R.Between limita las filas
               --U.P Establece límite inferior y C.R el superior.
               --suma desde el primer mes hasta el actual. 
           ) AS acumulado_categoria
    from ventas_mensuales
)
select mes,
       categoria,
       total_ventas,
       ranking_mes,
       acumulado_categoria,
       ROUND(AVG(total_ventas) over (partition by categoria), 2) as promedio_categoria, 
       -- Promedio mensual de ventas de la misma categoría y redondea el monto. 
       case
           when total_ventas >= AVG(total_ventas) over (PARTITION BY categoria)
               then 'Exitoso' --total de ventas supera o iguala el promedio total de ventas entonces es exitoso
           else 'Bajo el promedio' --si no, esta bajo el promedio. 
       end as desempenio --cierra el case queda resultado con alias desempenio. 
from metricas_ventana
order by mes, ranking_mes; --ordena por mes y por ranking





