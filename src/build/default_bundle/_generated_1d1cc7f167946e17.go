components {
  id: "main"
  component: "/main/main.script"
}
embedded_components {
  id: "background"
  type: "sprite"
  data: "default_animation: \"body\"\nmaterial: \"/builtins/materials/sprite.material\"\nsize {\n  x: 722.0\n  y: 1282.0\n}\nsize_mode: SIZE_MODE_MANUAL\ntextures {\n  sampler: \"texture_sampler\"\n  texture: \"/assets/atlases/main.atlas\"\n}\n"
  position {
    z: -0.1
  }
}
