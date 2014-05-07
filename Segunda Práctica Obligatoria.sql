1.- Crea una función DevolverNombreEquipo que reciba un código de equipo y devuelva el nombre del mismo. Si el equipo no existe devuelve la cadena “Error en código”.

create or replace function DevolverNombreEquipo (p_cod equipos.codequipo%type)
return equipos.nombre%type
is
	v_nombre equipos.nombre%type;
begin
	select nombre into v_nombre
	from equipos
	where codequipo=p_cod;
	return v_nombre;
exception
	when NO_DATA_FOUND then
		dbms_output.put_line('Error en el código '||p_cod);
		raise;
end DevolverNombreEquipo;
/

2.- Crea una función DevolverGolesEquipo que reciba el código de un equipo y devuelva el total de goles a favor y total de goles en contra. Contempla las excepciones oportunas. 

create or replace procedure DevolverGolesEquipo(p_cod equipos.codequipo,
												p_gf in out number,
												p_gc in out number)
is
	cursor c_partlocal
	is
	select gol_local, gol_visitante
	from partidos
	where codequipolocal=p_cod;

	cursor c_partvisit
	is
	select gol_local, gol_visitante
	from partidos
	where codequipovisit=p_cod;
	
	v_nombre VARCHAR2(80);
begin
	ComprobarExistenciaEquipo(p_cod);
	for v_partlocal in c_partlocal loop
		p_gf:=p_gf+gol_local;
		p_gc:=p_gc+gol_visitante;
	end loop;
	for v_partvisit in c_partvisit loop
		p_gc:=p_gc+gol_local;
		p_gf:=p_gf+gol_visitante;
	end loop;
end DevolverGolesEquipo;
/

create or replace procedure ComprobarExistenciaEquipo(p_cod equipos.codequipo%type)
is
	v_existe NUMBER;
	v_errmsg VARCHAR2(80);
begin
	select count(*) into v_existe
	from equipos
	where codequipo=p_cod;
exception
	when NO_DATA_FOUND then
		v_errmsg:='Codigo inexistente '||p_cod;
		raise_application_error(-20001,v_errmsg);
end ComprobarExistenciaEquipo;
/

3. Crea un procedimiento DevolverResultadosEquipo que reciba el código de un equipo y devuelva el número de partidos que ha ganado, el número de partidos que ha perdido y el número de partidos que ha empatado.  Contempla las excepciones oportunas.

create or replace procedure DevolverResultadosEquipo(p_cod equipos.codequipo%type,
													 p_contgan in out number,
													 p_contemp in out number,
													 p_contper in out number)
is
	cursor c_partidos
	is
	select codequipolocal, codequipovisitante, gol_local, gol_visitante
	from partidos
	where codequipolocal=p_cod or codequipovisitante=p_cod;

begin
	ComprobarExistenciaEquipo(p_cod);
	for v_partidos in c_partidos loop
		case 
			when p_cod=codequipolocal then
				if gol_local>gol_visitante then
					p_contgan:=p_contgan+1;
				elsif gol_local<gol_visitante then
					p_contper:=p_contper+1;
				else
					p_contemp:=p_contemp+1;
				end if;
			when p_cod=codequipovisitante then
				if gol_local<gol_visitante then
					p_contgan:=p_contgan+1;
				elsif gol_local>gol_visitante then
					p_contper:=p_contper+1;
				else
					p_contemp:=p_contemp+1;
				end if;
		end case;
	end loop;
end DevolverResultadosEquipo;
/

4. Realiza un procedimiento ActualizarClasificacion que haga lo siguiente:

Borra todos los registros de la tabla “Clasificación_liga”.
A partir de la tabla partidos, rellena la tabla “Clasificación_liga”, la información la obtiene sólo de los partidos de “liga”, para calcular los puntos debes considerar 3 puntos las victorias y 1 punto los empates.
Para terminar muestra la clasificación de los equipos, ordenados por puntos, y mostrando el nombre del equipo, en vez del código, todos los datos anteriores.

create or replace procedure ActualizarClasificación
is
begin
	BorrarClasificacion;
	RellenarClasificacion;
	MostrarClasificacion;
end ActualizarClasificacion;
/

create or replace procedure BorrarClasificacion
is
begin
	delete from clasificacion_liga;
end BorrarClasificacion;
/

create or replace procedure MostrarClasificación
is
	cursor c_tabla is
	select nombre, pj, pg, pe, pp, gf, gc, puntos
	from clasificacion_liga c, equipos e
	where c.codequipo=e.codequipo
	order by puntos desc;

	v_puesto number:=1;
begin
	dbms_output.put_line('CLASIFICACIÓN ACTUAL');
	dbms_output.put_line('Pos Nombre          PJ  PG  PE  PP  GF GC Puntos');
	dbms_output.put_line('________________________________________________');
	for v_tabla in c_tabla loop
		dbms_output.put_line(v_puesto||'. '||rpad(v_tabla.nombre,10,' ')||chr(9)||v_tabla.pj||
							 chr(9)||v_tabla.pg||chr(9)||v_tabla.pe||chr(9)||v_tabla.pp||chr(9)||
							 v_tabla.gf||chr(9)||v_tabla.gc||chr(9)||v_tabla.puntos);
		v_puesto:=v_puesto+1;
	end loop;
end MostrarClasificacion;
/

create or replace procedure RellenarClasificacion
is
	cursor c_equipos
	is
	select codequipo, nombre
	from equipos;

	v_contgan NUMBER:=0;
	v_contemp NUMBER:=0;
	v_contper NUMBER:=0;
	v_gf NUMBER:=0;
	v_gc NUMBER:=0;
	v_partjug number:=0;
	v_puntos number:=0;
begin
	for v_equipos in c_equipos loop
		InicializarContadores(v_contgan, v_contemp, v_contper, v_gf, v_gc);
		DevolverResultadosEquipo(v_equipos.codequipo, v_contgan, v_contemp, v_contper);
		DevolverGolesEquipo(v_equipos.codequipo, v_gf, v_gc);
		v_partjug:=v_contgan+v_contemp+v_contper;
		v_puntos:=v_contgan*3+v_contemp;
		insert into clasificacion_liga
		values(v_equipos.nombre, v_partjug, v_contgan, v_contemp, v_contper, v_gf, v_gc, v_puntos);
	end loop;
end RellenarClasificacion;
/

create or replace procedure InicializarContadores(p_contgan in out NUMBER
												  p_contemp in out NUMBER
												  p_contper in out NUMBER
	 											  p_contgf in out NUMBER
												  p_contgc in out NUMBER)
is
begin
	p_contgan:=0;
	p_contemp:=0;
	p_contper:=0;
	p_contgf:=0;
	p_contgc:=0;
end InicializarContadores;
/

5. Crear un procedimiento MostrarQuinielaJornada que reciba una jornada y muestre la quiniela de dicha jornada de la liga según los partidos jugados. El resultado debe ser de la siguiente manera:

	Nombre equipo1 – Nombre equipo2   (1, X o 2)

	El 1 será cuando el equipo1 (Local) haya ganado, la X cuando sea un empate y un 2 cuando el equipo 2 (visitante) haya ganado.

Se deben tratar las siguientes excepciones:

a) Tabla Equipos vacía
b) Tabla Partidos vacía.
c) No hay partidos de esa jornada.
 
Puedes crear los procedimientos o funciones que creas oportunos, o usar algunos de los que ya has realizado.

create or replace procedure MostrarQuinielaJornada(p_jornada partidos.jornada%type)
is
	cursor c_partidos
	is
	select codequipolocal, codequipovisitante, gol_local, gol_visitante
	from partidos
	where jornada=p_jornada;

	v_nombrelocal equipos.nombre%type;
	v_nombrevisit equipos.nombre%type;
	v_signo VARCHAR2(1);
begin
	comprobarexcepcionesquiniela(p_jornada);
	dbms_output.put_line('Quiniela de la Jornada '||p_jornada);
	for v_partidos in c_partidos loop
		v_nombrelocal:=DevolverNombreEquipo(codequipolocal);
		v_nombrevisit:=DevolverNombreEquipo(codequipovisitante);
		v_signo:=CalcularSigno(gol_local,gol_visit);
		dbms_output.put_line(v_nombrelocal||'  -  '||rpad(v_nombrevisit		,20,'.')||v_signo);
	end loop;
end MostrarQuinielaJornada;
/

create or replace function CalcularSigno(p_gl number, p_gv number)
return VARCHAR2
is
begin
	if p_gl>p_gv then
		return '1';
	elsif p_gl<p_gv then
		return '2';
	else
		return 'X';
	end if;
end CalcularSigno;
/

create or replace procedure comprobarexcepcionesquiniela(p_jornada partidos.jornada%type)
is
	v_numequipos 	NUMBER:=0;
	v_numpartidos 	NUMBER:=0;
	v_jornadajugada NUMBER:=0;
begin
	select count(*) into v_numequipos
	from equipos;
	select count(*) into v_numpartidos
	from partidos;
	select count(*) into v_jornadajugada
	from partidos
	where jornada=p_jornada;
	if v_numequipos=0 then
		raise_application_error(-20001,'No hay equipos');
	end if;
	if v_numpartidos=0 then
		raise_application_error(-20002,'No hay partidos');
	end if;
	if v_jornadajugada=0 then
		raise_application_error(-20003,'Jornada no disputada');
	end if;
end comprobarexcepcionesquiniela;
/
