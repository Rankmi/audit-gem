# Rankmi::Audit
- - - -
Gema para manejar las auditorías internas de Rankmi desde las diferentes APIs de la empresa. Permite la configuración y 
ejecución de request sobre la [API de auditoría](https://github.com/Rankmi/audit-api) de Rankmi.

## Modo de uso
La gema fue pensada para poder generar auditorías rápidamente desde cualquier parte del código, con dos simples métodos:

```ruby
# Para generar audits de acciones
Rankmi::Audit.track_action(tenant: 'some-enterprise-token', audit_hash: { 
    user_identifier: '',    # user.identifier desde la api de rankmi
    action_type: '',        # Algún tipo de acción establecido en la api de rankmi
    action_datetime: Time.zone.now,     # Fecha en que se produjo la acción (forma parte de un unique index, para evitar duplicaciones)
    action_object: {  }  # Hash con información extra de la acción
})

# Para generar audits de cambios
Rankmi::Audit.track_change(tenant: 'some-enterprise-token', audit_hash: {
    user_identifier: '',    # user.identifier desde la api de rankmi
    operator_user_identifier: '',   # user.identifier del usuario que realiza el cambio desde la api de rankmi
    enterprise_process_token: '',   # enterprise_process.token desde la api de rankmi, si es que tiene un proceso asociado
    survey_token: '',       # survey.token desde la api de rankmi, si es que tiene una encuesta asociada
    change_type: '',        # Algún tipo de cambio establecido en la api de rankmi
    change_datetime: Time.zone.now,  # Fecha en que se produjo el cambio (forma parte de un unique index, para evitar duplicaciones)
    change_object: {  }  # Hash con información extra del cambio
})
```

## Instalación y configuración

1. Agregar la gema al gemfile:
```ruby
gem 'rankmi-audit', git: "https://github.com/Rankmi/audit-gem"
```

2. Instalar la gema con bundler:
```shell script
bundle install
```

3. Configurar credenciales de la API de auditoría de rankmi en cada environment file:
```ruby
# Ejemplo: config/environments/development.rb

Rankmi::Audit.configure do |config|
  config.api_endpoint = 'http://localhost:8090'   # Audit endpoint donde se dispararán los requests
  config.api_key = 'rankmiAuditTestKey'           # AUDIT_AUTH_KEY definida como variable de ambiente en la API de auditoría
  config.api_secret = 'rankmiAuditTestSecret'     # AUDIT_AUTH_SECRET definido como variable de ambiente en la API de auditoría
  config.fail_silently = true   # Si es true, la gema no hará ningún raise Error, y sólo devolverá un boolean o nil al ejecutar un método. 
end 
```

4. Configurar los tenants permitidos en la gema, para que sólo se puedan crear audits para empresas registradas, por ejemplo:
```ruby
# config/initializers/rankmi_audits.rb
Rails.configuration.after_initialize do
  Rankmi::Audit.configuration.allowed_tenants = -> {
    Enterprise.all.pluck(:token)  # Mejor aún si se cachea el resultado de esta query, para evitar hacer muchas llamadas a la base de datos.
  } 
end
```

## Desarrollo

Luego de obtener el repo, ejecutar `bin/setup` para instalar las dependencias. Luego, ejecutar `rake test` para correr los tests.
