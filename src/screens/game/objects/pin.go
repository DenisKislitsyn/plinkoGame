components {
  id: "script"
  component: "/screens/game/objects/pin.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"ball_2\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/atlases/main.atlas\"\n"
  "}\n"
  ""
}
embedded_components {
  id: "sprite_bounce"
  type: "sprite"
  data: "default_animation: \"ball_3\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 44.0\n"
  "  y: 44.0\n"
  "}\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/atlases/main.atlas\"\n"
  "}\n"
  ""
  position {
    y: 1.0
    z: -0.01
  }
}
