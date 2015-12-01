Requirements
------------

The cookbook should run on any Linux flavor and it depends on the following cookbooks:

 - [docker cookbook (chef-cookbooks/docker)](https://github.com/chef-cookbooks/docker)
 - python cookbook

Attributes
----------
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['docker-compose']['config_directory']</tt></td>
    <td>String</td>
    <td>Specifies docker-compose yaml configuration storage directory</td>
    <td><tt>/etc/compose.d</tt></td>
  </tr>
</table>

Usage
-----
## docker-compose resource

### Actions

<table>
  <tr>
    <th>Action</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><tt>:up</tt></td>
    <td>Builds/pulls, (re)creates and starts containers</td>
  </tr>
  <tr>
    <td><tt>:start</tt></td>
    <td>Starts containers</td>
  </tr>
  <tr>
    <td><tt>:stop</tt></td>
    <td>Stops containers</td>
  </tr>
  <tr>
    <td><tt>:kill</tt></td>
    <td>Kills containers</td>
  </tr>
  <tr>
    <td><tt>:destroy</tt></td>
    <td>Kills and removes containers along with the configuration</td>
  </tr>
  <tr>
    <td><tt>:run</tt></td>
    <td>Invokes one-off docker-compose run command.</td>
  </tr>

</table>

### Attributes

<table>
  <tr>
    <th>Attribute</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><tt>project</tt></td>
    <td>Project name of docker-compose environment. Default value: <i>default</i>.</td>
  </tr>
   <tr>
    <td><tt>recreate</tt></td>
    <td>When set to true containers are recreated on every action :up. Default value: <i>false</i>.</td>
  </tr>
  <tr>
    <td><tt>source</tt></td>
    <td>The source of yaml configuration file. It can be either a cookbook file or a template (if the source string ends with <i>.erb</i>). In case the source is an URI or an array of URIs remote_file resource is used.</td>
  </tr>
  <tr>
    <td><tt>cookbook</tt></td>
    <td>The originating cookbook of a cookbook file or a template.</td>
  </tr>
  <tr>
    <td><tt>variables</tt></td>
    <td>A hash of variables which is passed to the template for its generation.</td>
  </tr>
  <tr>
    <td><tt>service</tt></td>
    <td>Service name used during docker-compose command. By default commands are applied to all docker-compose services defined in the environment yaml.</td>
  </tr>
  <tr>
    <td><tt>run_opts</tt></td>
    <td>Hash with configuration for one off command. Default value: <i>{remove: true, no_deps: true}</i></td>
  </tr>
</table>

## Invocation

```ruby
docker-compose 'training-webapp' do
  action :up
  source 'training.yml'
end

# one-off command example
docker-compose 'training one-off' do
  action :run
  source 'training.yml'

  service 'child'

  run_opts({
    command: %Q(-c "echo hello from one-off"),
    entrypoint: '/bin/sh'
  })
end
```

### One-off commands with docker-compose

Docker-compose resource provider operates differently from default docker-compose run, the key moment is that options *--rm* and *--no-deps* are enabled by default. Another nice thing helps you to dynamically redefine the entrypoint for a service in case this is needed just specify `run_opts[:entrypoint]`.

Contributing
------------

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: Denis Barishev (<denis.barishev@gmail.com>)
