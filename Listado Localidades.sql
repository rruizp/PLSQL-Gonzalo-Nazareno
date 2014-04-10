create or replace procedure listado
is
	cursor c_loc
	is
	select distinct loc
	from dept;

	v_totalloc NUMBER:=0;
	v_totalempresa NUMBER:=0;
begin
	comprobar_excepciones;
	dbms_output.put_line('Listado de Sueldos');
	for v_loc in c_loc loop
		v_totalloc:=ProcesarLocalidad(v_loc.loc);
		v_totalempresa:=v_totalempresa+v_totalloc;
	end loop;
	dbms_output.put_line('Total Sueldos de la Empresa: '||v_totalempresa);
end;

create or replace procedure comprobarexcepciones
is
	v_numemp NUMBER;
	e_tablaempvacia exception;
begin
	select count(*) into v_numemp
	from emp;
	if v_numemp=0 then
		raise e_tablaempvacia;
	end if;
exception
	when e_tablaempvacia then
		dbms_output.put_line('Tabla EMP sin datos');
		raise;
end;

create or replace function ProcesarLocalidad(p_loc dept.loc%type)
return NUMBER
is 
	cursor c_dept
	is
	select dname
	from dept
	where loc=p_loc;

	v_totaldept NUMBER:=0;
	v_totalloc NUMBER:=0;
begin
	dbms_output.put_line('Localidad: '||p_loc);
	for v_dept in c_dept loop
		v_totaldept:=ProcesarDepartamento(v_dept.dname);
		v_totalloc:=v_totalloc+v_totaldept;
	end loop;
	dbms_output.put_line('Total Sueldos de la Localidad: '||v_totalloc);
	return v_totalloc;
end;



create or replace function ProcesarDepartamento(p_dname dept.dname%type)
return NUMBER
is
	cursor c_emp
	is
	select ename, sal 
	from emp
	where deptno=v_deptno;
	
	v_deptno dept.deptno%type;
	v_total NUMBER:=0;
begin
	v_deptno:=DevolverCodDept(p_dname);
	dbms_output.put_line('Departamento: '||p_dname);
	for v_emp in c_emp loop
		dbms_output.put_line(chr(9)||rpad(v_emp.ename, 15,'.')||v_emp.sal);
		v_total:=v_total+v_emp.sal;
	end loop;
	dbms_output.put_line('Total Sueldos Departamento '||p_dname||': '||v_total);
	return v_total;	
end;
