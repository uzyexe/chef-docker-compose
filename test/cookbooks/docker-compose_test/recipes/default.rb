
fig 'training-webapp' do
  action [:up, :stop, :start]
  source 'training.yml'
end

fig 'one-off' do
  action :run
  source 'training.yml'

  service 'child'

  run_opts({
    remove: false,
    command: %Q(-c "echo hello from one-off"),
    entrypoint: '/bin/sh'
  })
end

# cloned from the previous one
fig('training-webapp') { action :destroy }
