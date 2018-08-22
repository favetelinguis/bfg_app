defmodule Resources.TestResources do
  def two_lay_one_back_unmatced do
    %{
      clk: "APBTAKhIAIhCAMVXAO4/",
      id: 2,
      oc: [
        %{
          id: "1.146966016",
          orc: [
            %{
              fullImage: true,
              id: 11_694_983,
              uo: [
                %{
                  id: "134746960863",
                  ot: "L",
                  p: 1000,
                  pd: 1_534_955_654_000,
                  pt: "L",
                  rac: "",
                  rc: "REG_LGA",
                  rfo: "",
                  rfs: "",
                  s: 2,
                  sc: 0,
                  side: "B",
                  sl: 0,
                  sm: 0,
                  sr: 2,
                  status: "E",
                  sv: 0
                }
              ]
            },
            %{
              fullImage: true,
              id: 10_174_023,
              uo: [
                %{
                  id: "134746941939",
                  ot: "L",
                  p: 1.01,
                  pd: 1_534_955_647_000,
                  pt: "L",
                  rac: "",
                  rc: "REG_LGA",
                  rfo: "",
                  rfs: "",
                  s: 2,
                  sc: 0,
                  side: "L",
                  sl: 0,
                  sm: 0,
                  sr: 2,
                  status: "E",
                  sv: 0
                }
              ]
            },
            %{
              fullImage: true,
              id: 27616,
              uo: [
                %{
                  id: "134746913448",
                  ot: "L",
                  p: 1.01,
                  pd: 1_534_955_638_000,
                  pt: "L",
                  rac: "",
                  rc: "REG_LGA",
                  rfo: "",
                  rfs: "",
                  s: 2,
                  sc: 0,
                  side: "L",
                  sl: 0,
                  sm: 0,
                  sr: 2,
                  status: "E",
                  sv: 0
                }
              ]
            }
          ]
        }
      ],
      op: "ocm",
      pt: 1_534_955_749_960
    }
  end

  def resub_two_lay_one_back_umnatched do
    %{
      clk: "AAAAAAAAAAAAAA==",
      conflateMs: 180_000,
      ct: "RESUB_DELTA",
      heartbeatMs: 5000,
      id: 2,
      initialClk: "W//T9t8HtgbiyOPkB32x97XdB3SE4+feB9wGkfLj2Qc=",
      oc: [
        %{
          id: "1.146966016",
          orc: [
            %{
              fullImage: true,
              id: 11_694_983,
              uo: [
                %{
                  id: "134746960863",
                  ot: "L",
                  p: 1000,
                  pd: 1_534_955_654_000,
                  pt: "L",
                  rac: "",
                  rc: "REG_LGA",
                  rfo: "",
                  rfs: "",
                  s: 2,
                  sc: 0,
                  side: "B",
                  sl: 0,
                  sm: 0,
                  sr: 2,
                  status: "E",
                  sv: 0
                }
              ]
            },
            %{
              fullImage: true,
              id: 10_174_023,
              uo: [
                %{
                  id: "134746941939",
                  ot: "L",
                  p: 1.01,
                  pd: 1_534_955_647_000,
                  pt: "L",
                  rac: "",
                  rc: "REG_LGA",
                  rfo: "",
                  rfs: "",
                  s: 2,
                  sc: 0,
                  side: "L",
                  sl: 0,
                  sm: 0,
                  sr: 2,
                  status: "E",
                  sv: 0
                }
              ]
            },
            %{
              fullImage: true,
              id: 27616,
              uo: [
                %{
                  id: "134746913448",
                  ot: "L",
                  p: 1.01,
                  pd: 1_534_955_638_000,
                  pt: "L",
                  rac: "",
                  rc: "REG_LGA",
                  rfo: "",
                  rfs: "",
                  s: 2,
                  sc: 0,
                  side: "L",
                  sl: 0,
                  sm: 0,
                  sr: 2,
                  status: "E",
                  sv: 0
                }
              ]
            }
          ]
        }
      ],
      op: "ocm",
      pt: 1_534_955_750_239
    }
  end

  def two_lay_one_back_canceled do
    %{
      clk: "AAAAAAAAAAAAAA==",
      conflateMs: 180_000,
      ct: "RESUB_DELTA",
      heartbeatMs: 5000,
      id: 2,
      initialClk: "W9+g998HtgaZi+TkB32BsLbdB3TTrOjeB9wG0qjk2Qc=",
      oc: [
        %{
          id: "1.146966016",
          orc: [
            %{
              id: 11_694_983,
              uo: [
                %{
                  id: "134746960863",
                  ot: "L",
                  p: 1000,
                  pd: 1_534_955_654_000,
                  pt: "L",
                  rac: "",
                  rc: "REG_LGA",
                  rfo: "",
                  rfs: "",
                  s: 2,
                  sc: 2,
                  side: "B",
                  sl: 0,
                  sm: 0,
                  sr: 0,
                  status: "EC",
                  sv: 0
                }
              ]
            },
            %{
              id: 10_174_023,
              uo: [
                %{
                  id: "134746941939",
                  ot: "L",
                  p: 1.01,
                  pd: 1_534_955_647_000,
                  pt: "L",
                  rac: "",
                  rc: "REG_LGA",
                  rfo: "",
                  rfs: "",
                  s: 2,
                  sc: 2,
                  side: "L",
                  sl: 0,
                  sm: 0,
                  sr: 0,
                  status: "EC",
                  sv: 0
                }
              ]
            },
            %{
              id: 27616,
              uo: [
                %{
                  id: "134746913448",
                  ot: "L",
                  p: 1.01,
                  pd: 1_534_955_638_000,
                  pt: "L",
                  rac: "",
                  rc: "REG_LGA",
                  rfo: "",
                  rfs: "",
                  s: 2,
                  sc: 2,
                  side: "L",
                  sl: 0,
                  sm: 0,
                  sr: 0,
                  status: "EC",
                  sv: 0
                }
              ]
            }
          ]
        }
      ],
      op: "ocm",
      pt: 1_534_955_911_656
    }
  end

  def some_mb do
    %{
      clk: "ALaAAQDKaADycAD1mwEAsW4=",
      id: 2,
      oc: [
        %{
          id: "1.147021307",
          orc: [
            %{
              fullImage: true,
              id: 10_590_219,
              mb: [[5.2, 2]],
              uo: [
                %{
                  avp: 5.2,
                  id: "134767822844",
                  md: 1_534_963_971_000,
                  ot: "L",
                  p: 4.6,
                  pd: 1_534_963_971_000,
                  pt: "L",
                  rac: "",
                  rc: "REG_LGA",
                  rfo: "",
                  rfs: "",
                  s: 2,
                  sc: 0,
                  side: "B",
                  sl: 0,
                  sm: 2,
                  sr: 0,
                  status: "EC",
                  sv: 0
                }
              ]
            },
            %{
              fullImage: true,
              id: 18_890_002,
              mb: [[5.8, 2]],
              uo: [
                %{
                  avp: 5.8,
                  id: "134767809512",
                  md: 1_534_963_965_000,
                  ot: "L",
                  p: 5,
                  pd: 1_534_963_965_000,
                  pt: "L",
                  rac: "",
                  rc: "REG_LGA",
                  rfo: "",
                  rfs: "",
                  s: 2,
                  sc: 0,
                  side: "B",
                  sl: 0,
                  sm: 2,
                  sr: 0,
                  status: "EC",
                  sv: 0
                }
              ]
            }
          ]
        }
      ],
      op: "ocm",
      pt: 1_534_964_080_984
    }
  end

  def some_ml do
    %{
      clk: "AAAAAAAAAAAAAA==",
      conflateMs: 180_000,
      ct: "RESUB_DELTA",
      heartbeatMs: 5000,
      id: 2,
      initialClk: "W6fWkuAHtgaF0/jkB32tjtDdB3TK7oTfB9wGlPj12Qc=",
      oc: [
        %{
          id: "1.147021307",
          orc: [
            %{
              id: 12_716_026,
              ml: [[4.8, 1.96]],
              uo: [
                %{
                  avp: 4.8,
                  id: "134768099056",
                  md: 1_534_964_119_000,
                  ot: "L",
                  p: 4.8,
                  pd: 1_534_964_112_000,
                  pt: "L",
                  rac: "",
                  rc: "REG_LGA",
                  rfo: "",
                  rfs: "",
                  s: 1.96,
                  sc: 0,
                  side: "L",
                  sl: 0,
                  sm: 1.96,
                  sr: 0,
                  status: "EC",
                  sv: 0
                },
                %{
                  id: "134768097917",
                  ot: "L",
                  p: 1.01,
                  pd: 1_534_964_111_000,
                  pt: "L",
                  rac: "",
                  rc: "REG_LGA",
                  rfo: "",
                  rfs: "",
                  s: 2,
                  sc: 2,
                  side: "L",
                  sl: 0,
                  sm: 0,
                  sr: 0,
                  status: "EC",
                  sv: 0
                }
              ]
            },
            %{
              id: 10_590_219,
              ml: [[4.9, 2.17]],
              uo: [
                %{
                  avp: 4.9,
                  id: "134768101261",
                  md: 1_534_964_113_000,
                  ot: "L",
                  p: 4.9,
                  pd: 1_534_964_113_000,
                  pt: "L",
                  rac: "",
                  rc: "REG_LGA",
                  rfo: "",
                  rfs: "",
                  s: 2.17,
                  sc: 0,
                  side: "L",
                  sl: 0,
                  sm: 2.17,
                  sr: 0,
                  status: "EC",
                  sv: 0
                }
              ]
            },
            %{
              id: 18_890_002,
              ml: [[6.4, 1.76]],
              uo: [
                %{
                  avp: 6.4,
                  id: "134768100960",
                  md: 1_534_964_113_000,
                  ot: "L",
                  p: 6.6,
                  pd: 1_534_964_113_000,
                  pt: "L",
                  rac: "",
                  rc: "REG_LGA",
                  rfo: "",
                  rfs: "",
                  s: 1.76,
                  sc: 0,
                  side: "L",
                  sl: 0,
                  sm: 1.76,
                  sr: 0,
                  status: "EC",
                  sv: 0
                },
                %{
                  id: "134768099512",
                  ot: "L",
                  p: 1.01,
                  pd: 1_534_964_112_000,
                  pt: "L",
                  rac: "",
                  rc: "REG_LGA",
                  rfo: "",
                  rfs: "",
                  s: 2,
                  sc: 2,
                  side: "L",
                  sl: 0,
                  sm: 0,
                  sr: 0,
                  status: "EC",
                  sv: 0
                }
              ]
            }
          ]
        }
      ],
      op: "ocm",
      pt: 1_534_964_123_752
    }
  end
end
